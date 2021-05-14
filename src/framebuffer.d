// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import bindbc.sdl;
import erupted;
import application, log;

void createFramebuffers(ref App app) {
  app.swapchain.swapChainFramebuffers.length = app.swapchain.swapChainImageViews.length;

  for (size_t i = 0; i < app.swapchain.swapChainImageViews.length; i++) {
    VkImageView[] attachments = [app.swapchain.swapChainImageViews[i], app.depthbuffer.depthImageView];

    VkFramebufferCreateInfo framebufferInfo = {
      sType: VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
      renderPass: app.renderpass,
      attachmentCount: cast(uint)attachments.length,
      pAttachments: &attachments[0],
      width: app.surface.capabilities.currentExtent.width,
      height: app.surface.capabilities.currentExtent.height,
      layers: 1
    };

    enforceVK(vkCreateFramebuffer(app.device, &framebufferInfo, null, &app.swapchain.swapChainFramebuffers[i]));
  }
  toStdout("%d Framebuffers created", app.swapchain.swapChainFramebuffers.length);
}
