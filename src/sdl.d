import bindbc.sdl;
import erupted;

import log, application;

void initSDL() {
  loadSDL();
  toStdout("SDL loaded %d", loadedSDLVersion);
  auto initSDL = SDL_Init(SDL_INIT_EVERYTHING);
  toStdout("SDL initialized: %d", initSDL);

  auto loadTTF = loadSDLTTF();
  toStdout("TTF loaded: %d", loadTTF);
  auto initTTF = TTF_Init();
  toStdout("TTF init: %d", initTTF);

  auto loadImage = loadSDLImage();
  toStdout("IMAGE loaded %d", loadImage);
  auto initImage = IMG_Init(app.imageflags);
  toStdout("IMAGE init: %d", initImage);

  auto loadMixer = loadSDLMixer();
  toStdout("MIXER loaded %d", loadMixer);
  auto initMixer = Mix_Init(0);
  toStdout("MIXER init: %d", initMixer);
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
