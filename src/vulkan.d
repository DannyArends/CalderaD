// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, commands, depthbuffer, descriptorset, framebuffer, pipeline, instance, images, glyphatlas;
import logicaldevice, physicaldevice, renderpass, square, surface, sync, swapchain, text, texture;
import uniformbuffer, vertex, vkdebug, wavefront;

void initVulkan(ref App app, 
                string vertPath = "data/shaders/vert.spv",
                string fragPath = "data/shaders/frag.spv",
                string fontPath = "data/fonts/FreeMono.ttf",
                string modelPath = "data/obj/viking_room.obj",
                string texturePath = "data/textures/viking_room.png") {
  toStdout("initializing Vulkan");
  version(Android){ }else{ //version(SDL)
    modelPath = "app/src/main/assets/" ~ modelPath;
    vertPath = "app/src/main/assets/" ~ vertPath;
    fragPath = "app/src/main/assets/" ~ fragPath;
    texturePath = "app/src/main/assets/" ~ texturePath;
    fontPath = "app/src/main/assets/" ~ fontPath;
  }

  app.glyphatlas = loadGlyphAtlas(fontPath, 80, '\U000000FF', 1024);
  app.enableValidationLayers = app.checkValidationLayerSupport(app.validationLayers[0]);
  app.loadInstanceExtensions();
  app.createInstance();
  app.setupDebugMessenger();
  app.pickPhysicalDevice();
  app.createSurface();
  app.loadSurfaceCapabilities();
  app.createLogicalDevice();

  app.createSwapChain();
  app.aquireSwapChainImages();
  app.createRenderPass();
  app.createDescriptorSetLayout();
  app.createGraphicsPipeline(vertPath, fragPath);
  app.createCommandPool();
  app.createDepthResources();
  app.createFramebuffers();
  app.createTextureImage(app.glyphatlas); // Creates the GlyphAtlas as textures[0]
  app.createTextureImage(texturePath);
  app.createTextureSampler();

  // Create several the geometries
  app.geometry ~= Square([0.0f,-4.0f,0.0f], app.glyphatlas.surface.w / app.glyphatlas.pointsize, app.glyphatlas.surface.h / app.glyphatlas.pointsize);
  app.geometry ~= Squares();
  app.geometry ~= Text(app.glyphatlas, "CanderaD\nv0.0.1");
  //app.geometry ~= app.loadWavefront(modelPath);

  app.createVertexBuffers();
  app.createIndexBuffers();
  app.createUniformBuffers();
  app.createDescriptorPool();
  app.createDescriptorSets();
  app.createCommandBuffers();
  app.createSyncObjects();
}

void recreateSwapChain(ref App app,
                       string vertPath = "data/shaders/vert.spv",
                       string fragPath = "data/shaders/frag.spv") {
  version(Android){ }else{ //version(SDL)
    vertPath = "app/src/main/assets/" ~ vertPath;
    fragPath = "app/src/main/assets/" ~ fragPath;
  }
  vkDeviceWaitIdle(app.device);

  app.cleanupSwapChain();
  app.loadSurfaceCapabilities();
  app.createSwapChain();
  app.aquireSwapChainImages();
  app.createRenderPass();
  app.createGraphicsPipeline(vertPath, fragPath);
  app.createDepthResources();
  app.createFramebuffers();
  app.createUniformBuffers();
  app.createDescriptorPool();
  app.createDescriptorSets();
  app.createCommandBuffers();

  app.synchronization.imagesInFlight.length = app.swapchain.swapChainImages.length;
  for (size_t i = 0; i < app.synchronization.imagesInFlight.length; i++) {
    app.synchronization.imagesInFlight[i] = VK_NULL_ND_HANDLE;
  }
}
