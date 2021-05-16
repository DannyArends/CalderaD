// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.exception;
import std.conv;
import std.datetime : MonoTime;

import calderad, depthbuffer, descriptorset, geometry, glyphatlas, pipeline, sync, surface, swapchain, texture, uniformbuffer, wavefront;

void enforceVK(VkResult res) { enforce(res == VkResult.VK_SUCCESS, res.to!string); }
SDL_bool enforceSDL(SDL_bool res) { enforce(res == SDL_bool.SDL_TRUE, to!string(SDL_GetError())); return(res); }

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
    apiVersion: VK_API_VERSION_1_2
  };

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
  Texture[] textureArray;
  VkSampler textureSampler;
  GraphicsPipeline pipeline;
  VkCommandPool commandPool;
  VkCommandBuffer[] commandBuffers;
  DepthBuffer depthbuffer;
  Geometry geometry;
  SyncObjects synchronization;
  GlyphAtlas glyphatlas;

  uint frame = 1;
  uint currentFrame = 0;

  MonoTime startTime;
  bool enabledValidationLayers = true;
  bool running = true;
  bool hasResized = false;
}

// Supporting structs
struct VkQueueFamilyIndices {
  uint graphicsFamily;
  uint presentFamily;
};

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

    vkDestroyBuffer(app.device, app.geometry.indexBuffer, null);
    vkFreeMemory(app.device, app.geometry.indexBufferMemory, null);
    toStdout("Index buffer destroyed");

    vkDestroyBuffer(app.device, app.geometry.vertexBuffer, null);
    vkFreeMemory(app.device, app.geometry.vertexBufferMemory, null);
    toStdout("Vertex buffer destroyed");

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
      //vkDestroyDebugUtilsMessengerEXT(app.instance, debugMessenger, null);
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
