// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.stdlib : exit;
import std.datetime : MonoTime;
import calderad, main, application, sdl, swapchain, vulkan;

// Immediate events to handle by the application
void handleApp(ref App app, const SDL_Event e) { 
  if(e.type == SDL_APP_WILLENTERBACKGROUND){ app.isMinimized = true; }
  if(e.type == SDL_APP_DIDENTERBACKGROUND){ app.cleanup(); app.running = false; }
}

/* sdlEventsFilter returns 1 will have the event go into the SDL_PollEvent queue, 0 if have handled 
   the event immediately. Android requires us to handle the application events, for now we just 
   shutdown on enter background, since we should properly ask for permission from the Android OS to 
   run in the background.
*/
extern(C) int sdlEventsFilter(void* userdata, SDL_Event* event) nothrow {
  if(!event) return(0);
  try {
    App* app = cast(App*)(userdata);
    switch (event.type) {
      case SDL_APP_TERMINATING: case SDL_QUIT: 
      (*app).cleanup(); exit(0); // Run cleanup and exit

      case SDL_APP_LOWMEMORY:      // Android application events
      case SDL_APP_WILLENTERBACKGROUND: case SDL_APP_DIDENTERBACKGROUND:
      case SDL_APP_WILLENTERFOREGROUND: case SDL_APP_DIDENTERFOREGROUND:
      toStdout("Android SDL immediate event hook: %s", toStringz(format("%s", event.type)));
      (*app).handleApp(*event); return(0);

      default: return(1);
    }
  } catch (Exception err){ toStdout("Hook error: %d", toStringz(err.msg)); }
  return(1);
}

void handleKeyboard(ref App app, const SDL_Event e) { 
  if (e.key.keysym.sym == SDLK_ESCAPE) {
    SDL_Event evt = { type: SDL_QUIT };
    SDL_PushEvent(&evt);
  }
}
void handleMouse(ref App app, const SDL_Event e) { }
void handleTouch(ref App app, const SDL_Event e) { }
void handleAudio(ref App app, const SDL_Event e) { }
void handleWindow(ref App app, const SDL_Event e) {
  toStdout("WindowEvent: %s", toStringz(format("%s", e.window.event)));
  if(e.window.event == SDL_WINDOWEVENT_RESIZED) app.resize(e.window.data1, e.window.data2);
  if(e.window.event == SDL_WINDOWEVENT_RESTORED){ app.isMinimized = false; }
  if(e.window.event == SDL_WINDOWEVENT_MINIMIZED){ app.isMinimized = true; }
}
void handleUser(ref App app, const SDL_Event e) { }
