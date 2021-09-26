// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.datetime : MonoTime;
import calderad, application, events, map, render, sdl, search, rnjesus, vulkan;

/* Main entry point to the program */
version (Android) {
  import core.memory;
  import core.runtime : rt_init;
  import std.format;

  extern(C) int SDL_main(int argc, char* argv) { // Hijack the SDL main
    int dRuntime = rt_init();
    GC.disable(); // The GC crashes on android
    App app;
    app.run(["android", format("--dRuntime=%s", dRuntime)]);
    return(0);
  }
// Other OS can just call run() directly (No known issues with garbage collection)
} else { 
  int main (string[] args) {
    App app;
    app.run(args);  return(0); 
  }
}

void run (ref App app, string[] args) {
  app.initSDL(); // Hook SDL immediately to be able to do output
  SDL_SetEventFilter(&sdlEventsFilter, &app); // Set the EventsFilter for immediate events
  app.testGenMap();
  for(size_t x = 0; x < 4; x++){
    char[] s1 = randomName([
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [99,1], [1,99]] // Pattern: consonant vowel vowel consonant
    ],
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [1,99], [99,1], [1,99]] // Pattern: consonant vowel consonant vowel consonant
    ]
    ]);

    char[] s2 = randomName([
    [
      [[50,50], [100,0]], // Pattern: vowel|consonant vowel
      [[50,50], [99,1], [1,99]] // Pattern: vowel|consonant vowel consonant
    ],
    [
      [[1,99], [99,1], [1,99], [99,1], [99,1]] // Pattern: consonant vowel consonant
    ],
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [1,99]] // Pattern: consonant vowel consonant vowel consonant
    ]
    ]);
    toStdout("%s", toStringz(format("%s", s1)));
    toStdout("%s", toStringz(format("%s", s2)));
  }
  //return;
  app.createWindow();
  app.startTime = MonoTime.currTime;
  app.initVulkan();

  while (app.running) {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
      toStdout("SDL event: %s", toStringz(format("%s", ev.type)));
      switch (ev.type) {

        case SDL_KEYDOWN: case SDL_KEYUP: case SDL_TEXTINPUT: case SDL_TEXTEDITING:
        app.handleKeyboard(ev); break; // Keyboard and text input

        case SDL_MOUSEMOTION: case SDL_MOUSEBUTTONDOWN: case SDL_MOUSEBUTTONUP: case SDL_MOUSEWHEEL:
        app.handleMouse(ev); break; // Mouse input

        case SDL_FINGERMOTION: case SDL_FINGERDOWN: case SDL_FINGERUP:
        app.handleTouch(ev); break; // Touch input

        case SDL_AUDIODEVICEADDED:
        app.handleAudio(ev); break; // SDL Audio

        case SDL_WINDOWEVENT:
        app.handleWindow(ev); break; // Window input

        case SDL_USEREVENT:
        app.handleUser(ev); break; // User event

        default: 
          toStdout("Unhandled SDL event: %s", toStringz(format("%s", ev.type)));
        break;
      }
    }
    if(!app.isMinimized) app.drawFrame();
  }
  toStdout("run() function completed, return to OS");
}
