import erupted;
import application, log, images, swapchain;

struct DepthBuffer {
  VkImage depthImage;
  VkDeviceMemory depthImageMemory;
  VkImageView depthImageView;
}

VkFormat findSupportedFormat(ref App app, const VkFormat[] candidates, VkImageTiling tiling, VkFormatFeatureFlags features) {
  foreach(VkFormat format; candidates) {
    VkFormatProperties props;
    vkGetPhysicalDeviceFormatProperties(app.physicalDevices[app.selected], format, &props);
    if (tiling == VK_IMAGE_TILING_LINEAR && (props.linearTilingFeatures & features) == features) {
      return format;
    } else if (tiling == VK_IMAGE_TILING_OPTIMAL && (props.optimalTilingFeatures & features) == features) {
      return format;
    }
  }
  assert(0, "failed to find supported format!");
}

VkFormat findDepthFormat(ref App app) {
  return app.findSupportedFormat(
    [VK_FORMAT_D32_SFLOAT, VK_FORMAT_D32_SFLOAT_S8_UINT, VK_FORMAT_D24_UNORM_S8_UINT],
    VK_IMAGE_TILING_OPTIMAL,
    VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT
  );
}

void createDepthResources(ref App app) {
  toStdout("Depth resources creation");
  VkFormat depthFormat = app.findDepthFormat();
  toStdout(" - depthFormat: %d", depthFormat);
  app.createImage(app.surface.capabilities.currentExtent.width, app.surface.capabilities.currentExtent.height, depthFormat, 
                  VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, 
                  VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &app.depthbuffer.depthImage, &app.depthbuffer.depthImageMemory);
  toStdout(" - image created: %p", app.depthbuffer.depthImage);
  app.depthbuffer.depthImageView = app.createImageView(app.depthbuffer.depthImage, depthFormat, VK_IMAGE_ASPECT_DEPTH_BIT);
  toStdout(" - image view created: %p", app.depthbuffer.depthImage);
  app.transitionImageLayout(app.depthbuffer.depthImage, depthFormat, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL);
  toStdout("Depth resources created");
}
