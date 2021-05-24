// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html
import core.stdc.string : memcpy;
import std.datetime : MonoTime, dur;
import std.math;
import matrix : mat4, radian, rotate, rotateZ, lookAt, perspective;
import calderad, buffer;

struct UniformBufferObject {
  mat4 model;
  mat4 view;
  mat4 proj;
  mat4 orientation; // Screen orientation
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
  auto time = (currentTime - app.startTime).total!"msecs"() / 100.0f;  // Update the current time

  UniformBufferObject ubo = {
    model: rotate(mat4.init, [0.0f, 0.0f, (PI * time) * radian(90.0f)]),
    view: lookAt([1.0f, 1.0f, 1.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 1.0f]),
    proj: perspective(45.0f, app.surface.capabilities.currentExtent.width / cast(float) app.surface.capabilities.currentExtent.height, 0.1f, 10.0f),
    orientation: mat4.init
  };

  // Adjust for screen orientation so that the world is always up
  if (app.surface.capabilities.currentTransform & VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR) {
    ubo.orientation.rotateZ(-90.0f);
  } else if (app.surface.capabilities.currentTransform & VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR) {
    ubo.orientation.rotateZ(-270.0f);
  } else if (app.surface.capabilities.currentTransform & VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR) {
    ubo.orientation.rotateZ(180.0f);
  }

  void* data;
  vkMapMemory(app.device, app.uniform.uniformBuffersMemory[currentImage], 0, ubo.sizeof, 0, &data);
  memcpy(data, &ubo, ubo.sizeof);
  vkUnmapMemory(app.device, app.uniform.uniformBuffersMemory[currentImage]);
  //toStdout("UniformBuffer updated");
}
