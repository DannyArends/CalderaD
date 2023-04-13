// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.exception;
import std.conv;
import std.datetime : MonoTime;

import calderad, camera, depthbuffer, descriptorset, geometry, map, glyphatlas, pipeline;
import sound, sync, surface, swapchain, texture, tileatlas, uniformbuffer, vkdebug, wavefront;

void enforceVK(VkResult res) { enforce(res == VkResult.VK_SUCCESS, res.to!string); }
SDL_bool enforceSDL(SDL_bool res) { enforce(res == SDL_TRUE, to!string(SDL_GetError())); return(res); }

/*
  Main application structure, aliasses the SDL_Window

  Should stores all global SDL/Window/Vulkan related variables
  To keep code encapsulated, the idea should be to avoid passing it by ref unless absolutely needed 
  (Currently this is not the case, unfortunately). By keeping acces to this structure const() as much 
  as possible, we can in future avoid threading issues when we de-couple the main loop with the render 
  loop.
*/
struct App {
  version (Android) {
    uint[2] pos = [0, 0];
    uint imageflags = IMG_INIT_JPG | IMG_INIT_PNG;
  } else {
    uint[2] pos = [SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED];
    uint imageflags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
  }
  SDL_WindowFlags flags = SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN;
  SDL_Window* ptr;
  alias ptr this;

  uint width = 1024;
  uint height = 768;
  VkApplicationInfo info  = {
    pApplicationName: "CalderaDemo", 
    applicationVersion: 0, 
    pEngineName: "CalderaD", 
    engineVersion: 0,
    apiVersion: VK_MAKE_API_VERSION( 1, 2, 0, 0 )
  };

  bool isRotating = true;
  bool enableValidationLayers = false;
  const(char*)[] validationLayers = ["VK_LAYER_KHRONOS_validation"];
  VkDebugUtilsMessengerEXT debugMessenger;

  const(char)*[] instanceExtensions;
  VkInstance instance;
  uint nPhysDevices;
  uint selected;
  VkPhysicalDevice[] physicalDevices;
  VkDevice device;
  Surface surface;
  VkQueueFamilyIndices familyIndices;
  VkQueue presentQueue;
  VkQueue graphicsQueue;
  SwapChain swapchain;
  VkRenderPass renderpass;
  Descriptor descriptor;
  Uniform uniform;
  TileAtlas tileAtlas;
  Map map;
  Texture[] textureArray;
  VkSampler textureSampler;
  GraphicsPipeline pipeline;
  VkCommandPool commandPool;
  VkCommandBuffer[] commandBuffers;
  DepthBuffer depthbuffer;
  Geometry[] geometry;
  SyncObjects synchronization;
  GlyphAtlas glyphatlas;

  Camera camera;
  WavFMT[] soundfx;
  float soundEffectGain = 0.8;

  uint frame = 1;
  uint currentFrame = 0;

  MonoTime startTime;
  bool enabledValidationLayers = true;
  bool running = true;
  bool isMinimized = false;
  bool hasResized = false;
}

// Supporting structs
struct VkQueueFamilyIndices {
  uint graphicsFamily;
  uint presentFamily;
};

void resize(ref App app, uint w, uint h) {
  SDL_SetWindowSize(app.ptr, w, h);
  if (w == 0 || h == 0){ app.isMinimized = true; return; }
  app.isMinimized = false;
  app.hasResized = true;
}

float aspectRatio(ref App app){
  return(app.surface.capabilities.currentExtent.width / cast(float) app.surface.capabilities.currentExtent.height);
}

void cleanup(ref App app) {
  if (app.device != VK_NULL_HANDLE) {
    toStdout("Waiting for and destroying Vulkan device");
    vkDeviceWaitIdle(app.device);

    app.cleanupSwapChain();

    foreach(texture; app.textureArray){
      vkDestroyImage(app.device, texture.textureImage, null);
      vkDestroyImageView(app.device, texture.textureImageView, null);
      vkFreeMemory(app.device, texture.textureImageMemory, null);
    }
    vkDestroySampler(app.device, app.textureSampler, null);
    toStdout("Textures and sampler destroyed");

    vkDestroyDescriptorSetLayout(app.device, app.descriptor.descriptorSetLayout, null);

    for(size_t i = 0; i < app.geometry.length; i++) {
      vkDestroyBuffer(app.device, app.geometry[i].instanceBuffer, null);
      vkFreeMemory(app.device, app.geometry[i].instanceBufferMemory, null);
      toStdout("Instance buffer destroyed");

      vkDestroyBuffer(app.device, app.geometry[i].indexBuffer, null);
      vkFreeMemory(app.device, app.geometry[i].indexBufferMemory, null);
      toStdout("Index buffer destroyed");

      vkDestroyBuffer(app.device, app.geometry[i].vertexBuffer, null);
      vkFreeMemory(app.device, app.geometry[i].vertexBufferMemory, null);
      toStdout("Vertex buffer destroyed");
    }

    for (size_t i = 0; i < app.synchronization.MAX_FRAMES_IN_FLIGHT; i++) {
      vkDestroySemaphore(app.device, app.synchronization.renderFinishedSemaphores[i], null);
      vkDestroySemaphore(app.device, app.synchronization.imageAvailableSemaphores[i], null);
      vkDestroyFence(app.device, app.synchronization.inFlightFences[i], null);
    }
    toStdout("Semaphores and fenches destroyed");

    vkDestroyCommandPool(app.device, app.commandPool, null);
    vkDestroyDevice(app.device, null);
    toStdout("Device destroyed");

    vkDestroySurfaceKHR(app.instance, app.surface, null);
    toStdout("Surface destroyed");
    if (app.enabledValidationLayers) {
      destroyDebugMessenger(app.instance, app.debugMessenger, null);
      toStdout("Validation debug layer destroyed");
    }
    vkDestroyInstance(app.instance, null);
    toStdout("Instance destroyed");
  }
  toStdout("Destroying app and unloading SDL and Vulkan libraries");
  SDL_DestroyWindow(app);

  SDL_Vulkan_UnloadLibrary();
  toStdout("SDL Quit after rendering %d frames", app.frame);
  SDL_Quit();
}
