// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, uniformbuffer;
import matrix : mat4, radian, rotate, lookAt, perspective;

struct Descriptor {
  VkDescriptorPool descriptorPool;
  VkDescriptorSet[] descriptorSets;
  VkDescriptorSetLayout descriptorSetLayout;
  VkDescriptorSetLayout[] layouts;
}

void createDescriptorSets(ref App app) {
  app.descriptor.layouts.length = app.textureArray.length;
  for (size_t i = 0; i < app.textureArray.length; i++) {
     app.descriptor.layouts[i] = app.descriptor.descriptorSetLayout;
  }
  VkDescriptorSetAllocateInfo allocInfo = {
    sType: VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
    descriptorPool: app.descriptor.descriptorPool,
    descriptorSetCount: cast(uint)(app.textureArray.length),
    pSetLayouts: &app.descriptor.layouts[0]
  };
  
  app.descriptor.descriptorSets.length = app.textureArray.length;
  enforceVK(vkAllocateDescriptorSets(app.device, &allocInfo, &app.descriptor.descriptorSets[0]));
  
  for (size_t i = 0; i < app.textureArray.length; i++) {
    VkDescriptorBufferInfo bufferInfo = {
      buffer: app.uniform.uniformBuffers[i],
      offset: 0,
      range: UniformBufferObject.sizeof
    };

    VkDescriptorImageInfo img = {
      imageLayout: VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
      imageView: app.textureArray[i].textureImageView, // Texture 0 is reserved for font
      sampler: app.textureSampler
    };
    toStdout("wrote textures %d", app.textureArray.length);

    VkWriteDescriptorSet[2] descriptorWrites = [
      {
        sType: VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet: app.descriptor.descriptorSets[i],
        dstBinding: 0,
        dstArrayElement: 0,
        descriptorType: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        descriptorCount: 1,
        pBufferInfo: &bufferInfo,
        pImageInfo: null,
        pTexelBufferView: null
      },
      {
        sType: VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet: app.descriptor.descriptorSets[i],
        dstBinding: 1,
        dstArrayElement: 0,
        descriptorType: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        descriptorCount: 1,
        pImageInfo: &img
      }
    ];
    vkUpdateDescriptorSets(app.device, descriptorWrites.length, &descriptorWrites[0], 0, null);
    toStdout("wrote descriptor %d", i);
  }
  toStdout("createDescriptorSets");
}

void createDescriptorSetLayout(ref App app) {
  VkDescriptorSetLayoutBinding uboLayoutBinding = {
    binding: 0,
    descriptorCount: 1,
    descriptorType: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    pImmutableSamplers: null,
    stageFlags: VK_SHADER_STAGE_VERTEX_BIT
  };

  VkDescriptorSetLayoutBinding samplerLayoutBinding = {
    binding: 1,
    descriptorCount: 1,
    descriptorType: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    pImmutableSamplers: null,
    stageFlags: VK_SHADER_STAGE_FRAGMENT_BIT
  };
  
  VkDescriptorSetLayoutBinding[2] bindings = [uboLayoutBinding, samplerLayoutBinding];

  VkDescriptorSetLayoutCreateInfo layoutInfo = {
    sType: VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
    bindingCount: bindings.length,
    pBindings: &bindings[0]
  };
  enforceVK(vkCreateDescriptorSetLayout(app.device, &layoutInfo, null, &app.descriptor.descriptorSetLayout));
  toStdout("created DescriptorSetLayout");
}


void createDescriptorPool(ref App app) {
  VkDescriptorPoolSize[2] poolSizes = [
    { type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, descriptorCount: cast(uint)(app.textureArray.length) },
    { type: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptorCount: cast(uint)(app.textureArray.length) },
  ];

  VkDescriptorPoolCreateInfo poolInfo = {
    sType: VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
    poolSizeCount: poolSizes.length,
    pPoolSizes: &poolSizes[0],
    maxSets: cast(uint)(app.textureArray.length)
  };
  
  enforceVK(vkCreateDescriptorPool(app.device, &poolInfo, null, &app.descriptor.descriptorPool));
  toStdout("created DescriptorPool");
}

