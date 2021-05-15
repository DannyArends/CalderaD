// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.stdlib;
import std.conv;
import std.string;

import bindbc.sdl;
import erupted;

import application, log, io, vertex;

struct GraphicsPipeline {
  VkPipelineLayout pipelineLayout;
  VkPipeline graphicsPipeline;
}

VkShaderModule createShaderModule(App app, const uint[] code) {
  VkShaderModuleCreateInfo createInfo = {
    sType: VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
    codeSize: cast(uint) code.length,
    pCode: &code[0]
  };
  VkShaderModule shaderModule;
  enforceVK(vkCreateShaderModule(app.device, &createInfo, null, &shaderModule));
  return(shaderModule);
}

GraphicsPipeline createGraphicsPipeline(ref App app, string vertPath = "data/shaders/vert.spv", string fragPath = "data/shaders/frag.spv"){
  toStdout("creating pipeline");

  auto vertShaderCode = readFile(vertPath);
  auto fragShaderCode = readFile(fragPath);

  VkShaderModule vertShaderModule = app.createShaderModule(cast(uint[])vertShaderCode);
  VkShaderModule fragShaderModule = app.createShaderModule(cast(uint[])fragShaderCode);

  // Stage
  VkPipelineShaderStageCreateInfo vertShaderStageInfo = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
    stage: VK_SHADER_STAGE_VERTEX_BIT,
    Module: vertShaderModule,
    pName: "main"
  };
  
  VkPipelineShaderStageCreateInfo fragShaderStageInfo = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
    stage: VK_SHADER_STAGE_FRAGMENT_BIT,
    Module: fragShaderModule,
    pName: "main"
  };

  VkPipelineShaderStageCreateInfo[] shaderStages = [ vertShaderStageInfo, fragShaderStageInfo ];

  auto bindingDescription = Vertex.getBindingDescription();
  auto attributeDescriptions = Vertex.getAttributeDescriptions();
  
  // Vertex input
  VkPipelineVertexInputStateCreateInfo vertexInputInfo = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
    vertexBindingDescriptionCount: 1,
    pVertexBindingDescriptions: &bindingDescription, // Optional
    vertexAttributeDescriptionCount: attributeDescriptions.length,
    pVertexAttributeDescriptions: &attributeDescriptions[0] // Optional
  };
  
  // Input Assembly
  VkPipelineInputAssemblyStateCreateInfo inputAssembly = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
    topology: VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    primitiveRestartEnable: VK_FALSE
  };

  VkViewport viewport = { x: 0.0f, y: 0.0f,
    width: cast(float) app.surface.capabilities.currentExtent.width,
    height: cast(float) app.surface.capabilities.currentExtent.height,
    minDepth: 0.0f,
    maxDepth: 1.0f
  };

  VkRect2D scissor = { offset: {0, 0}, extent: app.surface.capabilities.currentExtent };

  VkPipelineViewportStateCreateInfo viewportState = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
    viewportCount: 1,
    pViewports: &viewport,
    scissorCount: 1,
    pScissors: &scissor
  };

  VkPipelineRasterizationStateCreateInfo rasterizer = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
    depthClampEnable: VK_FALSE,
    rasterizerDiscardEnable: VK_FALSE,
    polygonMode: VK_POLYGON_MODE_FILL,
    lineWidth: 1.0f,
    cullMode: VK_CULL_MODE_BACK_BIT,
    frontFace: VK_FRONT_FACE_COUNTER_CLOCKWISE,
    depthBiasEnable: VK_FALSE,
    depthBiasConstantFactor: 0.0f, // Optional
    depthBiasClamp: 0.0f, // Optional
    depthBiasSlopeFactor: 0.0f // Optional
  };

  VkPipelineMultisampleStateCreateInfo multisampling = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
    sampleShadingEnable: VK_FALSE,
    rasterizationSamples: VK_SAMPLE_COUNT_1_BIT,
    minSampleShading: 1.0f, // Optional
    pSampleMask: null, // Optional
    alphaToCoverageEnable: VK_FALSE, // Optional
    alphaToOneEnable: VK_FALSE // Optional
  };

  VkPipelineColorBlendAttachmentState colorBlendAttachment = {
    colorWriteMask: VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT,
    blendEnable: VK_FALSE,
    srcColorBlendFactor: VK_BLEND_FACTOR_ONE, // Optional
    dstColorBlendFactor: VK_BLEND_FACTOR_ZERO, // Optional
    colorBlendOp: VK_BLEND_OP_ADD, // Optional
    srcAlphaBlendFactor: VK_BLEND_FACTOR_ONE, // Optional
    dstAlphaBlendFactor: VK_BLEND_FACTOR_ZERO, // Optional
    alphaBlendOp: VK_BLEND_OP_ADD // Optional
  };

  VkPipelineColorBlendStateCreateInfo colorBlending = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    logicOpEnable: VK_FALSE,
    logicOp: VK_LOGIC_OP_COPY, // Optional
    attachmentCount: 1,
    pAttachments: &colorBlendAttachment,
    blendConstants: [0.0f, 0.0f, 0.0f, 0.0f]
  };
  
  VkDynamicState[] dynamicStates = [ VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_LINE_WIDTH];

  VkPipelineDynamicStateCreateInfo dynamicState = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
    dynamicStateCount: 2,
    pDynamicStates: &dynamicStates[0]
  };
  
  VkPipelineLayoutCreateInfo pipelineLayoutInfo = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
    setLayoutCount: 1, // Optional
    pSetLayouts: &app.descriptor.descriptorSetLayout, // Optional
    pushConstantRangeCount: 0, // Optional
    pPushConstantRanges: null, // Optional
  };
  enforceVK(vkCreatePipelineLayout(app.device, &pipelineLayoutInfo, null, &app.pipeline.pipelineLayout));
  toStdout("Vulkan pipeline layout created");

  VkPipelineDepthStencilStateCreateInfo depthStencil = {
    sType: VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
    depthTestEnable: VK_TRUE,
    depthWriteEnable: VK_TRUE,
    depthCompareOp: VK_COMPARE_OP_LESS,
    depthBoundsTestEnable: VK_FALSE,
    minDepthBounds: 0.0f, // Optional
    maxDepthBounds: 1.0f, // Optional
    stencilTestEnable: VK_FALSE,
    front: {}, // Optional
    back: {} // Optional
  };

  VkGraphicsPipelineCreateInfo pipelineInfo = {
    sType: VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
    stageCount: 2,
    pStages: &shaderStages[0],
    pVertexInputState: &vertexInputInfo,
    pInputAssemblyState: &inputAssembly,
    pViewportState: &viewportState,
    pRasterizationState: &rasterizer,
    pMultisampleState: &multisampling,
    pDepthStencilState: &depthStencil, // Optional
    pColorBlendState: &colorBlending,
    pDynamicState: null, // Optional
    layout: app.pipeline.pipelineLayout,
    renderPass: app.renderpass,
    subpass: 0,
    basePipelineHandle: VK_NULL_ND_HANDLE, // Optional
  };
  enforceVK(vkCreateGraphicsPipelines(app.device, VK_NULL_ND_HANDLE, 1, &pipelineInfo, null, &app.pipeline.graphicsPipeline));
  toStdout("Vulkan GraphicsPipeline created");
  vkDestroyShaderModule(app.device, fragShaderModule, null);
  vkDestroyShaderModule(app.device, vertShaderModule, null);
  return(app.pipeline);
}
