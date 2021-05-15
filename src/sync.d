// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad;

struct SyncObjects {
  const int MAX_FRAMES_IN_FLIGHT = 2;
  VkFence[] imagesInFlight;
  VkSemaphore[] imageAvailableSemaphores;
  VkSemaphore[] renderFinishedSemaphores;
  VkFence[] inFlightFences;
}
void createSyncObjects(ref App app) {
  toStdout("creating SyncObjects");
  app.synchronization.imagesInFlight.length = app.swapchain.swapChainImages.length;
  for (size_t i = 0; i < app.synchronization.imagesInFlight.length; i++) {
    app.synchronization.imagesInFlight[i] = VK_NULL_ND_HANDLE;
  }

  app.synchronization.imageAvailableSemaphores.length = app.synchronization.MAX_FRAMES_IN_FLIGHT;
  app.synchronization.renderFinishedSemaphores.length = app.synchronization.MAX_FRAMES_IN_FLIGHT;
  app.synchronization.inFlightFences.length = app.synchronization.MAX_FRAMES_IN_FLIGHT;

  VkSemaphoreCreateInfo semaphoreInfo = { sType: VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
  VkFenceCreateInfo fenceInfo = { sType: VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags: VK_FENCE_CREATE_SIGNALED_BIT };
  
  for (size_t i = 0; i < app.synchronization.MAX_FRAMES_IN_FLIGHT; i++) {
    enforceVK(vkCreateSemaphore(app.device, &semaphoreInfo, null, &app.synchronization.imageAvailableSemaphores[i]));
    enforceVK(vkCreateSemaphore(app.device, &semaphoreInfo, null, &app.synchronization.renderFinishedSemaphores[i])); 
    enforceVK(vkCreateFence(app.device, &fenceInfo, null, &app.synchronization.inFlightFences[i]));
  }
  toStdout("Finished creating SyncObjects");
}
