// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.random;

import calderad, commands, cube, depthbuffer, descriptorset, framebuffer, geometry, pipeline, instance, images, glyphatlas;
import logicaldevice, matrix, physicaldevice, renderpass, square, surface, sync, swapchain, text, texture;
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
  app.createTextureImage(texturePath); // Texture from disk as texture[1]
  app.createTextureSampler();

  // Create several the geometries
  app.geometry ~= Rectangle(app.glyphatlas.surface.w / app.glyphatlas.pointsize, app.glyphatlas.surface.h / app.glyphatlas.pointsize);
  app.geometry[($-1)].instances[0].offset = scale(app.geometry[($-1)].instances[0].offset, [0.2f, 0.2f, 0.2f]);
  app.geometry[($-1)].instances[0].offset = translate(app.geometry[($-1)].instances[0].offset, [5.0f, 2.0f, 2.0f]);

  app.geometry ~= Squares();
  app.geometry[($-1)].texture = 1;

  app.geometry ~= Text(app.glyphatlas, "CanderaD\nv0.0.1");
  app.geometry[($-1)].instances[0].offset = scale(app.geometry[($-1)].instances[0].offset, [2.0f, 2.0f, 2.0f]);
  app.geometry[($-1)].instances[0].offset = rotate(app.geometry[($-1)].instances[0].offset, [0.0f, 0.0f, 0.0f]);
  app.geometry[($-1)].instances[0].offset = translate(app.geometry[($-1)].instances[0].offset, [0.0f, 0.0f, 1.0f]);

  app.geometry ~= Cube();
  app.geometry[($-1)].instances[0].offset = translate(app.geometry[($-1)].instances[0].offset, [-2.0f, 2.0f, 1.0f]);

  app.geometry ~= app.loadWavefront(modelPath);
  for(int x = -5; x < 5; x++){
    for(int y = -5; y < 5; y++){
      GeometryInstanceData instance;
      auto scalefactor = uniform(0.2f, 0.6f);
      instance.offset = scale(instance.offset, [scalefactor, scalefactor, scalefactor]);
      instance.offset = translate(instance.offset, [cast(float) x * 2, cast(float)y, 0.0f]);
      app.geometry[($-1)].instances ~= instance;
    }
  }

  app.createVertexBuffers();
  app.createIndexBuffers();
  app.createInstanceBuffers();

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
  if (app.surface.isMinimized()) { app.isMinimized = true; return; }
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
