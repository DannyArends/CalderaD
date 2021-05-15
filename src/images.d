// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import bindbc.sdl;
import erupted;

import application, buffer, commands, log, swapchain;

VkDeviceSize imageSize(SDL_Surface* surface){ return(surface.w * surface.h * (surface.format.BitsPerPixel / 8)); }

void createImage(ref App app, uint width, uint height, VkFormat format, 
            VkImageTiling tiling, VkImageUsageFlags usage, VkMemoryPropertyFlags properties, 
            VkImage* image, VkDeviceMemory* imageMemory){

  VkExtent3D extent = {
    width: width,
    height: height,
    depth: 1,
  };

  VkImageCreateInfo imageInfo = {
    sType: VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
    imageType: VK_IMAGE_TYPE_2D,
    extent: extent,
    mipLevels: 1,
    arrayLayers: 1,
    format: format,
    tiling: tiling,
    initialLayout: VK_IMAGE_LAYOUT_UNDEFINED,
    usage: usage,
    sharingMode: VK_SHARING_MODE_EXCLUSIVE,
    samples: VK_SAMPLE_COUNT_1_BIT,
    flags: 0
  };
  
  enforceVK(vkCreateImage(app.device, &imageInfo, null, image));

  VkMemoryRequirements memRequirements;
  vkGetImageMemoryRequirements(app.device, (*image), &memRequirements);

  VkMemoryAllocateInfo allocInfo = {
    sType: VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
    allocationSize: memRequirements.size,
    memoryTypeIndex: app.findMemoryType(memRequirements.memoryTypeBits, properties)

  };
  toStdout(" - allocating: %d bytes", memRequirements.size);
  enforceVK(vkAllocateMemory(app.device, &allocInfo, null, imageMemory));

  vkBindImageMemory(app.device, (*image), (*imageMemory), 0);
}

void transitionImageLayout(ref App app, VkImage image, VkFormat format, VkImageLayout oldLayout, VkImageLayout newLayout) {
  toStdout("transitionImageLayout");
  VkCommandBuffer commandBuffer = app.beginSingleTimeCommands();
  toStdout(" - Single time command started");
  VkImageSubresourceRange subresourceRange = {
    aspectMask: VK_IMAGE_ASPECT_COLOR_BIT,
    baseMipLevel: 0,
    levelCount: 1,
    baseArrayLayer: 0,
    layerCount: 1,
  };
  
  if (newLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL) {
    subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT;
    if (hasStencilComponent(format)){
      toStdout("Has stencil component");
      subresourceRange.aspectMask |= VK_IMAGE_ASPECT_STENCIL_BIT;
    }
  } else {
    subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
  }
  
  VkImageMemoryBarrier barrier = {
    sType: VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
    oldLayout: oldLayout,
    newLayout: newLayout,
    srcQueueFamilyIndex: VK_QUEUE_FAMILY_IGNORED,
    dstQueueFamilyIndex: VK_QUEUE_FAMILY_IGNORED,
    image: image,
    subresourceRange: subresourceRange,
  };

  VkPipelineStageFlags sourceStage;
  VkPipelineStageFlags destinationStage;

  if (oldLayout == VK_IMAGE_LAYOUT_UNDEFINED && newLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

    sourceStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    destinationStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
  } else if (oldLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL && newLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

    sourceStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
    destinationStage = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
  } else if (oldLayout == VK_IMAGE_LAYOUT_UNDEFINED && newLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL) {
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;

    sourceStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    destinationStage = VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
  }else {
    toStdout("unsupported layout transition!");
  }

  vkCmdPipelineBarrier(commandBuffer, sourceStage, destinationStage, 0, 0, null, 0, null, 1, &barrier);
  app.endSingleTimeCommands(commandBuffer);
  toStdout(" - Single time command finished");
}

VkImageView createImageView(App app, VkImage image, VkFormat format, VkImageAspectFlags aspectMask = VK_IMAGE_ASPECT_COLOR_BIT) {
  VkImageSubresourceRange subresourceRange = {
    aspectMask: aspectMask,
    baseMipLevel: 0,
    levelCount: 1,
    baseArrayLayer: 0,
    layerCount: 1,
  };

  VkImageViewCreateInfo viewInfo = {
    sType: VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
    image: image,
    viewType: VK_IMAGE_VIEW_TYPE_2D,
    format: format,
    subresourceRange: subresourceRange
  };
  VkImageView imageView;
  enforceVK(vkCreateImageView(app.device, &viewInfo, null, &imageView));
  toStdout("imageView %p to %p created", imageView, image);
  return imageView;
}

void copyBufferToImage(ref App app, VkBuffer buffer, VkImage image, uint width, uint height) {
    VkCommandBuffer commandBuffer = app.beginSingleTimeCommands();
    VkOffset3D imageOffset = { 0, 0, 0 };
    VkExtent3D imageExtent = { width, height, 1 };

    VkImageSubresourceLayers imageSubresource = {
      aspectMask: VK_IMAGE_ASPECT_COLOR_BIT,
      mipLevel: 0,
      baseArrayLayer: 0,
      layerCount: 1
    };
    
    VkBufferImageCopy region = {
      bufferOffset: 0,
      bufferRowLength: 0,
      bufferImageHeight: 0,
      imageSubresource: imageSubresource,
      imageOffset: imageOffset,
      imageExtent: imageExtent
    };

    SDL_Log("copyBufferToImage %dx%d", width, height);

    vkCmdCopyBufferToImage(commandBuffer, buffer, image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);
    app.endSingleTimeCommands(commandBuffer);
}
