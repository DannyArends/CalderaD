// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, swapchain, uniformbuffer, vulkan;

void drawFrame(ref App app) {
  vkWaitForFences(app.device, 1, &app.synchronization.inFlightFences[app.currentFrame], VK_TRUE, uint.max);
  //toStdout("vkWaitForFences: inFlight Fence[%d]", currentFrame);

  uint imageIndex;
  VkResult result = vkAcquireNextImageKHR(app.device, app.swapchain.swapChain, size_t.max, app.synchronization.imageAvailableSemaphores[app.currentFrame], VK_NULL_ND_HANDLE, &imageIndex);
  if (result == VK_ERROR_OUT_OF_DATE_KHR) {
    toStdout("VK_ERROR_OUT_OF_DATE_KHR");
    return app.recreateSwapChain();
  }
  enforce(result == VkResult.VK_SUCCESS || result == VK_SUBOPTIMAL_KHR, "failed to acquire swap chain image!");
  //toStdout("vkAcquireNextImageKHR: %d %d", result, imageAvailableSemaphores[currentFrame]);

  app.updateUniformBuffer(imageIndex);
  //toStdout("updateUniformBuffer: %d", imageIndex);

  // Check if a previous frame is using this image (i.e. there is its fence to wait on)
  if (app.synchronization.imagesInFlight[imageIndex] != VK_NULL_ND_HANDLE) {
    //toStdout("vkWaitForFences: %d", imagesInFlight[imageIndex]);
    vkWaitForFences(app.device, 1, &app.synchronization.imagesInFlight[imageIndex], VK_TRUE, uint.max);
  }
  // Mark the image as now being in use by this frame
  app.synchronization.imagesInFlight[imageIndex] = app.synchronization.inFlightFences[app.currentFrame];
  
  //toStdout("Renderer next frame %d image = %d", frame, imageIndex);
  VkSemaphore[] waitSemaphores = [app.synchronization.imageAvailableSemaphores[app.currentFrame]];
  VkPipelineStageFlags[] waitStages = [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT];
  VkSemaphore[] signalSemaphores = [app.synchronization.renderFinishedSemaphores[app.currentFrame]];

  VkSubmitInfo submitInfo = {
    sType: VK_STRUCTURE_TYPE_SUBMIT_INFO,
    waitSemaphoreCount: cast(uint)waitSemaphores.length,
    pWaitSemaphores: &waitSemaphores[0],
    pWaitDstStageMask: &waitStages[0],
    commandBufferCount: 1,
    pCommandBuffers: &app.commandBuffers[imageIndex],
    signalSemaphoreCount: cast(uint)signalSemaphores.length,
    pSignalSemaphores: &signalSemaphores[0]
  };

  vkResetFences(app.device, 1, &app.synchronization.inFlightFences[app.currentFrame]);
  //toStdout("vkResetFences: %d", inFlightFences[currentFrame]);

  enforceVK(vkQueueSubmit(app.graphicsQueue, 1, &submitInfo, app.synchronization.inFlightFences[app.currentFrame]));
  //toStdout("vkQueueSubmit: %d", inFlightFences[currentFrame]);

  VkSwapchainKHR[] swapChains = [app.swapchain.swapChain];

  VkPresentInfoKHR presentInfo = {
    sType: VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
    waitSemaphoreCount: cast(uint)signalSemaphores.length,
    pWaitSemaphores: &signalSemaphores[0],
    swapchainCount: cast(uint)swapChains.length,
    pSwapchains: &swapChains[0],
    pImageIndices: &imageIndex,
    pResults: null // Optional
  };

  result = vkQueuePresentKHR(app.presentQueue, &presentInfo);
  //toStdout("vkQueuePresentKHR: %d", result);

  if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR || app.hasResized) {
    if(app.hasResized) app.hasResized = false;
    return app.recreateSwapChain();
  } else {
    enforce(result == VkResult.VK_SUCCESS, "failed to present swap chain image!");
  }
  //toStdout("Render completed, queue wait idle");
  app.currentFrame = (app.frame++) % app.synchronization.MAX_FRAMES_IN_FLIGHT;
}
