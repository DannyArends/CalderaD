import erupted;

import application, commands, depthbuffer, descriptorset, framebuffer, pipeline, instance, images;
import log, logicaldevice, physicaldevice, renderpass, surface, sync, swapchain, texture, vertex, uniformbuffer, wavefront;

void initVulkan(ref App app, 
                string vertPath = "data/shaders/vert.spv",
                string fragPath = "data/shaders/frag.spv",
                string modelPath = "data/obj/viking_room.obj",
                string texturePath = "data/textures/viking_room.png") {
  toStdout("initializing Vulkan");
  version(Android){ }else{ //version(SDL)
    modelPath = "app/src/main/assets/" ~ modelPath;
    vertPath = "app/src/main/assets/" ~ vertPath;
    fragPath = "app/src/main/assets/" ~ fragPath;
    texturePath = "app/src/main/assets/" ~ texturePath;
  }
  app.loadInstanceExtensions();
  app.createInstance();
  app.pickPhysicalDevice();
  app.createSurface();
  app.loadSurfaceCapabilities();
  app.createLogicalDevice();
  app.geometry = app.loadWavefront(modelPath);
  app.createSwapChain();
  app.aquireSwapChainImages();
  app.createRenderPass();
  app.createDescriptorSetLayout();
  app.createGraphicsPipeline(vertPath, fragPath);
  app.createCommandPool();
  app.createDepthResources();
  app.createFramebuffers();
  app.createTextureImage(texturePath);
  app.createTextureSampler();
  app.createVertexBuffer();
  app.createIndexBuffer();
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