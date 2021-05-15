// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, images, surface;

struct SwapChain {
  VkImage[] swapChainImages;
  VkImageView[] swapChainImageViews;

  VkSwapchainKHR swapChain;
  alias swapChain this;

  VkRenderPass renderpass;
  VkCommandPool commandPool;

  VkImage depthImage;
  VkDeviceMemory depthImageMemory;
  VkImageView depthImageView;

  VkFramebuffer[] swapChainFramebuffers;

  SwapChain* oldChain;
}

SwapChain createSwapChain(ref App app, SwapChain* oldChain = null) {
  SwapChain swapchain = { oldChain: oldChain };

  //SwapChain creation
  VkSwapchainCreateInfoKHR swapchainCreateInfo = {
    sType: VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
    surface: app.surface,
    minImageCount: app.surface.capabilities.minImageCount,
    imageFormat: app.surface.surfaceformats[0].format,
    imageColorSpace: app.surface.surfaceformats[0].colorSpace,
    imageExtent: app.surface.capabilities.currentExtent,
    imageArrayLayers: 1,
    imageUsage: VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
    imageSharingMode: VK_SHARING_MODE_EXCLUSIVE,
    preTransform: app.surface.capabilities.currentTransform,
    compositeAlpha: VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
    presentMode: VK_PRESENT_MODE_FIFO_KHR,
    clipped: VK_TRUE,
    oldSwapchain: VK_NULL_ND_HANDLE,
  };

  enforceVK(vkCreateSwapchainKHR(app.device, &swapchainCreateInfo, null, &swapchain.swapChain));
  toStdout("Swapchain created");
  app.swapchain = swapchain;
  return(app.swapchain);
}

void aquireSwapChainImages(ref App app) {
  // Aquire swapchain images
  uint imageCount;
  vkGetSwapchainImagesKHR(app.device, app.swapchain.swapChain, &imageCount, null);
  app.swapchain.swapChainImages.length = imageCount;
  vkGetSwapchainImagesKHR(app.device, app.swapchain.swapChain, &imageCount, &app.swapchain.swapChainImages[0]);
  toStdout("Swapchain images: %d", imageCount);

  // Allocate space for the imageviews
  app.swapchain.swapChainImageViews.length = app.swapchain.swapChainImages.length;

  VkComponentMapping components = {
    r: VK_COMPONENT_SWIZZLE_IDENTITY,
    g: VK_COMPONENT_SWIZZLE_IDENTITY,
    b: VK_COMPONENT_SWIZZLE_IDENTITY,
    a: VK_COMPONENT_SWIZZLE_IDENTITY,
  };
  
  VkImageSubresourceRange subresourceRange = {
    aspectMask: VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel: 0, levelCount: 1, baseArrayLayer: 0, layerCount: 1
  };

  for (size_t i = 0; i < app.swapchain.swapChainImages.length; i++) {
    app.swapchain.swapChainImageViews[i] = app.createImageView(app.swapchain.swapChainImages[i], app.surface.surfaceformats[0].format);
  }
  toStdout("Swapchain image views: %d", app.swapchain.swapChainImageViews.length);
}

void cleanupSwapChain(ref App app) {
  vkDestroyImageView(app.device, app.depthbuffer.depthImageView, null);
  vkDestroyImage(app.device, app.depthbuffer.depthImage, null);
  vkFreeMemory(app.device, app.depthbuffer.depthImageMemory, null);
  
  for (size_t i = 0; i < app.swapchain.swapChainFramebuffers.length; i++) {
    vkDestroyFramebuffer(app.device, app.swapchain.swapChainFramebuffers[i], null);
  }
  vkFreeCommandBuffers(app.device, app.commandPool, cast(uint)app.commandBuffers.length, &app.commandBuffers[0]);

  vkDestroyPipeline(app.device, app.pipeline.graphicsPipeline, null);
  vkDestroyPipelineLayout(app.device, app.pipeline.pipelineLayout, null);
  vkDestroyRenderPass(app.device, app.renderpass, null);

  for (size_t i = 0; i < app.swapchain.swapChainImageViews.length; i++) {
    vkDestroyImageView(app.device, app.swapchain.swapChainImageViews[i], null);
  }
  vkDestroySwapchainKHR(app.device, app.swapchain.swapChain, null);
  for (size_t i = 0; i < app.swapchain.swapChainImages.length; i++) {
    vkDestroyBuffer(app.device, app.uniform.uniformBuffers[i], null);
    vkFreeMemory(app.device, app.uniform.uniformBuffersMemory[i], null);
  }
  vkDestroyDescriptorPool(app.device, app.descriptor.descriptorPool, null);
  SDL_Log("Swapchain cleaned");
}
