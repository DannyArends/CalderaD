// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad;

void initSDL(ref App app) {
  loadSDL();
  SDL_version v;
  SDL_GetVersion(&v);
  toStdout("SDL loaded v%d.%d.%d", v.major, v.minor, v.patch);
  auto initSDL = SDL_Init(SDL_INIT_EVERYTHING);
  toStdout("SDL initialized: %d", initSDL);

  auto loadTTF = loadSDLTTF();
  SDL_TTF_VERSION(&v);
  toStdout("TTF loaded: v%d.%d.%d", v.major, v.minor, v.patch);
  auto initTTF = TTF_Init();
  toStdout("TTF init: %d", initTTF);

  auto loadImage = loadSDLImage();
  SDL_IMAGE_VERSION(&v);
  toStdout("IMAGE loaded v%d.%d.%d", v.major, v.minor, v.patch);
  auto initImage = IMG_Init(app.imageflags);
  toStdout("IMAGE init: %d", initImage);

  auto loadMixer = loadSDLMixer();
  SDL_MIXER_VERSION(&v);
  toStdout("MIXER loaded v%d.%d.%d", v.major, v.minor, v.patch);
  auto initMixer = Mix_Init(0);
  toStdout("MIXER init: %d", initMixer);
  auto openAudio = Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
  toStdout("OpenAudio : %d", openAudio);
}

void createWindow(ref App app) {
  version(Android) {
    SDL_DisplayMode displayMode;
    if ( SDL_GetCurrentDisplayMode( 0, &displayMode ) == 0 ) {
      app.width = displayMode.w;
      app.height = displayMode.h;
    }
  }
  toStdout("Window Dimensions: %dx%d", app.width, app.height);
  app.ptr = SDL_CreateWindow(app.info.pApplicationName, app.pos[0], app.pos[1], app.width, app.height, app.flags);
  loadGlobalLevelFunctions(cast(PFN_vkGetInstanceProcAddr)SDL_Vulkan_GetVkGetInstanceProcAddr());
  toStdout("loadGlobalLevelFunctions loaded using SDL Vulkan");
}
