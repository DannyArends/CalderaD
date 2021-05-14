import core.stdc.string : memcpy;
import std.datetime : MonoTime, dur;

import bindbc.sdl;
import erupted;

import application, buffer, log;
import matrix : mat4, radian, rotate, lookAt, perspective;

struct UniformBufferObject {
  mat4 model;
  mat4 view;
  mat4 proj;
}

struct Uniform {
  VkBuffer[] uniformBuffers;
  VkDeviceMemory[] uniformBuffersMemory;
}

void createUniformBuffers(ref App app) {
  VkDeviceSize bufferSize = UniformBufferObject.sizeof;

  app.uniform.uniformBuffers.length = app.swapchain.swapChainImages.length;
  app.uniform.uniformBuffersMemory.length = app.swapchain.swapChainImages.length;

  for (size_t i = 0; i <  app.swapchain.swapChainImages.length; i++) {
    app.createBuffer(bufferSize, VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &app.uniform.uniformBuffers[i], &app.uniform.uniformBuffersMemory[i]);
  }
  toStdout("created UniformBuffers");
}

void updateUniformBuffer(ref App app, uint currentImage) {
  MonoTime currentTime = MonoTime.currTime;
  auto time = (currentTime - app.startTime).total!"msecs"() / 100.0f;
  //SDL_Log("Time passed: %f", time);
  UniformBufferObject ubo = {
    model: rotate(mat4.init, [0.0f, 0.0f, time * radian(90.0f)]),
    view: lookAt([1.0f, 1.0f, 1.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 1.0f]),
    proj: perspective(45.0f, app.surface.capabilities.currentExtent.width / cast(float) app.surface.capabilities.currentExtent.height, 0.1f, 10.0f)
  };
  void* data;
  vkMapMemory(app.device, app.uniform.uniformBuffersMemory[currentImage], 0, ubo.sizeof, 0, &data);
  memcpy(data, &ubo, ubo.sizeof);
  vkUnmapMemory(app.device, app.uniform.uniformBuffersMemory[currentImage]);
  //SDL_Log("updateUniformBuffer");
}
