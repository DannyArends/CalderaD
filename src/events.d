// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.datetime : MonoTime;
import calderad, application;

void handleKeyboard(ref App app, const SDL_Event e) { 
  if(e.key.keysym.sym == SDLK_ESCAPE) app.running = false;
}
void handleMouse(ref App app, const SDL_Event e) { }
void handleTouch(ref App app, const SDL_Event e) { }
void handleAudio(ref App app, const SDL_Event e) { }
void handleWindow(ref App app, const SDL_Event e) {
  if(e.window.event == SDL_WINDOWEVENT_RESIZED) app.resize(e.window.data1, e.window.data2);
}
void handleUser(ref App app, const SDL_Event e) { }
