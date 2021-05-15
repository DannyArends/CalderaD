// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

/* Main entry point to the program */
version (Android) {
  import core.memory;
  import core.runtime : rt_init;
  import std.format;

  extern(C) int SDL_main(int argc, char* argv) { // Hijack the SDL main
    int dRuntime = rt_init();
    GC.disable(); // The GC crashes on android
    run(["android", format("--dRuntime=%s", dRuntime)]);
    return(0);
  }
// Other OS can just call run() directly (No known issues with garbage collection)
} else { 
  int main (string[] args) { run(args);  return(0); }
}
import std.datetime : MonoTime;
import bindbc.sdl;
import application, log, render, sdl, vulkan;

void run (string[] args) {
  initSDL(); // Hook SDL immediately to be able to do output
  app.createWindow();
  app.startTime = MonoTime.currTime;
  app.initVulkan();

  while (app.running) {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_QUIT) app.running = false;
      if (ev.type == SDL_KEYUP && ev.key.keysym.sym == SDLK_ESCAPE) app.running = false;
      if (ev.type == SDL_WINDOWEVENT && ev.window.event == SDL_WINDOWEVENT_RESIZED){ 
      SDL_SetWindowSize(app.ptr, ev.window.data1, ev.window.data2);
      app.hasResized = true;
      }
    }
    app.drawFrame(); // have the device draw a frame;
  }
  toStdout("app.cleanup()");
  app.cleanup();
  toStdout("run() function completed, return to OS");
}
