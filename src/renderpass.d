// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import bindbc.sdl;
import erupted;

import application, depthbuffer, log;

VkRenderPass createRenderPass(ref App app) {
  VkAttachmentDescription colorAttachment = {
    format: app.surface.surfaceformats[0].format,
    samples: VK_SAMPLE_COUNT_1_BIT,
    loadOp: VK_ATTACHMENT_LOAD_OP_CLEAR,
    storeOp: VK_ATTACHMENT_STORE_OP_STORE,
    stencilLoadOp: VK_ATTACHMENT_LOAD_OP_DONT_CARE,
    stencilStoreOp: VK_ATTACHMENT_STORE_OP_DONT_CARE,
    initialLayout: VK_IMAGE_LAYOUT_UNDEFINED,
    finalLayout: VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
  };

  VkAttachmentReference colorAttachmentRef = { attachment: 0, layout: VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL };

  VkAttachmentDescription depthAttachment = {
    format: app.findDepthFormat(),
    samples: VK_SAMPLE_COUNT_1_BIT,
    loadOp: VK_ATTACHMENT_LOAD_OP_CLEAR,
    storeOp: VK_ATTACHMENT_STORE_OP_DONT_CARE,
    stencilLoadOp: VK_ATTACHMENT_LOAD_OP_DONT_CARE,
    stencilStoreOp: VK_ATTACHMENT_STORE_OP_DONT_CARE,
    initialLayout: VK_IMAGE_LAYOUT_UNDEFINED,
    finalLayout: VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
  };
  
  VkAttachmentReference depthAttachmentRef = { attachment: 1, layout: VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL };

  VkSubpassDescription subpass = { 
    pipelineBindPoint: VK_PIPELINE_BIND_POINT_GRAPHICS,
    colorAttachmentCount: 1,
    pColorAttachments: &colorAttachmentRef,
    pDepthStencilAttachment: &depthAttachmentRef
  };
  
  VkSubpassDependency dependency = {
    srcSubpass: VK_SUBPASS_EXTERNAL,
    srcAccessMask: 0,
    srcStageMask: VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
    dstSubpass: 0,
    dstAccessMask: VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
    dstStageMask: VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
  };

  VkAttachmentDescription[2] attachments = [colorAttachment, depthAttachment];

  VkRenderPassCreateInfo renderPassInfo = {
    sType: VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
    attachmentCount: attachments.length,
    pAttachments: &attachments[0],
    subpassCount: 1,
    pSubpasses: &subpass,
    dependencyCount: 1,
    pDependencies: &dependency
  };

  enforceVK(vkCreateRenderPass(app.device, &renderPassInfo, null, &app.renderpass));
  toStdout("Vulkan render pass created");
  return(app.renderpass);
}
