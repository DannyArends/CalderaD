// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.stdlib : exit;
import std.datetime : MonoTime;
import calderad, camera, main, application, sdl, swapchain, vulkan;

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
      break;
      case SDL_APP_LOWMEMORY: // Android immediate application events, fallthrough switch
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
  if (e.type == SDL_KEYDOWN) {
    if(e.key.keysym.sym == SDLK_p) app.isRotating = !app.isRotating;
    if(e.key.keysym.sym == SDLK_PAGEUP){ app.camera.move([ 0.0f,  0.0f, 1.0f]); }
    if(e.key.keysym.sym == SDLK_PAGEDOWN){ app.camera.move([ 0.0f,  0.0f, -1.0f]); }
    if(e.key.keysym.sym == SDLK_w || e.key.keysym.sym == SDLK_UP){ app.camera.move(app.camera.forward()); }
    if(e.key.keysym.sym == SDLK_s || e.key.keysym.sym == SDLK_DOWN){ app.camera.move(app.camera.back());  }
    if(e.key.keysym.sym == SDLK_a || e.key.keysym.sym == SDLK_LEFT){ app.camera.move(app.camera.left());  }
    if(e.key.keysym.sym == SDLK_d || e.key.keysym.sym == SDLK_RIGHT){ app.camera.move(app.camera.right());  }
  }

}
void handleMouse(ref App app, const SDL_Event e) { 
  if(e.type == SDL_MOUSEBUTTONDOWN){
    if (e.button.button == SDL_BUTTON_LEFT) { app.camera.isdrag[0] = true; }
    if (e.button.button == SDL_BUTTON_RIGHT) { app.camera.isdrag[1] = true;}
  }
  if(e.type == SDL_MOUSEBUTTONUP){
    if (e.button.button == SDL_BUTTON_LEFT) { app.camera.isdrag[0] = false; }
    if (e.button.button == SDL_BUTTON_RIGHT) { app.camera.isdrag[1] = false;}
  }
  if(e.type == SDL_MOUSEMOTION){
    if(app.camera.isdrag[1]) app.camera.drag(e.motion.xrel, e.motion.yrel);
  }
  if(e.type == SDL_MOUSEWHEEL){
    if (e.wheel.y < 0 && app.camera.distance  >= -40.0f) app.camera.distance -= 0.5f;
    if (e.wheel.y > 0 && app.camera.distance  <= -1.0f) app.camera.distance += 0.5f;
    app.camera.move([ 0.0f,  0.0f,  0.0f]);
  }
}

void handleTouch(ref App app, const SDL_Event event) {
  SDL_TouchFingerEvent e = event.tfinger;
  if(event.type == SDL_FINGERDOWN) {
    if(e.fingerId == 0) app.camera.isdrag[0] = true;
  }
  if(event.type == SDL_FINGERUP) {
    if(e.fingerId == 0) app.camera.isdrag[0] = false;
    app.camera.move(app.camera.forward());
  }
  if(event.type == SDL_FINGERMOTION) {
    toStdout("TouchMotion: %f %f [%f %f] by %.1f [%d]\n", e.x, e.y, e.dx * app.width, e.dy * app.height, e.pressure, e.fingerId);
    if(e.fingerId == 0) app.camera.drag(e.dx * app.width, e.dy * app.height);
    if(e.fingerId == 1) {
      if (e.dy < 0 && app.camera.distance  >= -30.0f) app.camera.distance -= 0.1f;
      if (e.dy > 0 && app.camera.distance  <= -1.0f) app.camera.distance += 0.1f;
      app.camera.move([ 0.0f,  0.0f,  0.0f]);
    }
  }
}

void handleAudio(ref App app, const SDL_Event e) { }
void handleWindow(ref App app, const SDL_Event e) {
  //toStdout("WindowEvent: %s", toStringz(format("%s", e.window.event)));
  if(e.window.event == SDL_WINDOWEVENT_RESIZED) app.resize(e.window.data1, e.window.data2);
  if(e.window.event == SDL_WINDOWEVENT_RESTORED){ app.isMinimized = false; }
  if(e.window.event == SDL_WINDOWEVENT_MINIMIZED){ app.isMinimized = true; }
}
void handleUser(ref App app, const SDL_Event e) { }
