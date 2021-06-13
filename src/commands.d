// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, vertex, matrix, pushconstant;

void createCommandPool(ref App app) {
  VkCommandPoolCreateInfo poolInfo = {
    sType: VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
    queueFamilyIndex: app.familyIndices.graphicsFamily,
    flags: 0
  };

  enforceVK(vkCreateCommandPool(app.device, &poolInfo, null, &app.commandPool));
  toStdout("Commandpool at queue idx %d created", poolInfo.queueFamilyIndex);
}

@nogc VkCommandBuffer beginSingleTimeCommands(ref App app) nothrow {
  VkCommandBufferAllocateInfo allocInfo = {
    sType: VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    level: VK_COMMAND_BUFFER_LEVEL_PRIMARY,
    commandPool: app.commandPool,
    commandBufferCount: 1,
  };

  VkCommandBuffer commandBuffer;
  vkAllocateCommandBuffers(app.device, &allocInfo, &commandBuffer);

  VkCommandBufferBeginInfo beginInfo = {
    sType: VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    flags: VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
  };
  vkBeginCommandBuffer(commandBuffer, &beginInfo);
  return commandBuffer;
}

@nogc void endSingleTimeCommands(ref App app, VkCommandBuffer commandBuffer) nothrow {
    vkEndCommandBuffer(commandBuffer);

    VkSubmitInfo submitInfo = {sType: VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount: 1, pCommandBuffers: &commandBuffer };
    vkQueueSubmit(app.graphicsQueue, 1, &submitInfo, VK_NULL_ND_HANDLE);
    vkQueueWaitIdle(app.graphicsQueue);

    vkFreeCommandBuffers(app.device, app.commandPool, 1, &commandBuffer);
}


void createCommandBuffers(ref App app) {
  app.commandBuffers.length = app.swapchain.swapChainFramebuffers.length;
  VkCommandBufferAllocateInfo allocInfo = {
    sType: VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
    commandPool: app.commandPool,
    level: VK_COMMAND_BUFFER_LEVEL_PRIMARY,
    commandBufferCount: cast(uint) app.commandBuffers.length
  };
  enforceVK(vkAllocateCommandBuffers(app.device, &allocInfo, &app.commandBuffers[0]));
  toStdout("Command buffer with %d buffers created", allocInfo.commandBufferCount);

  for (size_t i = 0; i < app.commandBuffers.length; i++) {
    VkCommandBufferBeginInfo beginInfo = {
      sType: VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
      pInheritanceInfo: null // Optional
    };
    enforceVK(vkBeginCommandBuffer(app.commandBuffers[i], &beginInfo));
    toStdout("Command buffer %d recording", i);

    VkRect2D renderArea = {
      offset: { x:0, y:0 },
      extent: {
               width: app.surface.capabilities.currentExtent.width,
               height: app.surface.capabilities.currentExtent.height
              }
    };

    VkClearValue[2] clearValues;
    VkClearColorValue color = { float32: [0.0f, 0.0f, 0.0f, 1.0f] };
    VkClearDepthStencilValue depthStencil =  { depth: 1.0f, stencil: 0 };
    clearValues[0].color = color;
    clearValues[1].depthStencil = depthStencil;

    VkRenderPassBeginInfo renderPassInfo = {
      sType: VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
      renderPass: app.renderpass,
      framebuffer: app.swapchain.swapChainFramebuffers[i],
      renderArea: renderArea,
      clearValueCount: clearValues.length,
      pClearValues: &clearValues[0]
    };

    vkCmdBeginRenderPass(app.commandBuffers[i], &renderPassInfo, VK_SUBPASS_CONTENTS_INLINE);
    toStdout("Render pass recording to %d", i);
    vkCmdBindPipeline(app.commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, app.pipeline.graphicsPipeline);
    
    for(size_t j = 0; j < app.geometry.length; j++) {
      VkBuffer[] vertexBuffers = [app.geometry[j].vertexBuffer];
      VkDeviceSize[] offsets = [0];

      PushConstant pc = {
        oId: to!int(j),
        tId: app.geometry[j].texture,
        model: app.geometry[j].filemodel
      };
      vkCmdPushConstants(app.commandBuffers[i], app.pipeline.pipelineLayout, 
                         VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0, 
                         PushConstant.sizeof, &pc);

      vkCmdBindVertexBuffers(app.commandBuffers[i], VERTEX_BUFFER_BIND_ID, 1, &app.geometry[j].vertexBuffer, &offsets[0]);
      vkCmdBindVertexBuffers(app.commandBuffers[i], INSTANCE_BUFFER_BIND_ID, 1, &app.geometry[j].instanceBuffer, &offsets[0]);

      vkCmdBindIndexBuffer(app.commandBuffers[i], app.geometry[j].indexBuffer, 0, VK_INDEX_TYPE_UINT32);

      vkCmdBindDescriptorSets(app.commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, app.pipeline.pipelineLayout, 0, 1, &app.descriptor.descriptorSets[app.geometry[j].texture], 0, null);

      vkCmdDrawIndexed(app.commandBuffers[i], cast(uint)app.geometry[j].indices.length, cast(uint)app.geometry[j].instances.length, 0, 0, 0);
    }
    vkCmdEndRenderPass(app.commandBuffers[i]);
    enforceVK(vkEndCommandBuffer(app.commandBuffers[i]));
    toStdout("Render pass finished to %d", i);
  }
}
