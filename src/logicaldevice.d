// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad;

void getGraphicsQueueFamilyIndex(ref App app) {
  uint numQueues;
  app.familyIndices.graphicsFamily = uint.max;

  vkGetPhysicalDeviceQueueFamilyProperties(app.physicalDevices[app.selected], &numQueues, null);
  toStdout("Number of queues on selected device(%d): %d", app.selected, numQueues);
  auto queueFamilyProperties = new VkQueueFamilyProperties[](numQueues);
  vkGetPhysicalDeviceQueueFamilyProperties(app.physicalDevices[app.selected], &numQueues, queueFamilyProperties.ptr);
  foreach (i, fproperties; queueFamilyProperties) {
    if (fproperties.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
      VkBool32 presentSupport = false;
      toStdout("VK_QUEUE_GRAPHICS_BIT: %d", i);
      enforceVK(vkGetPhysicalDeviceSurfaceSupportKHR(app.physicalDevices[app.selected], cast(uint)i, app.surface, &presentSupport));
      if (presentSupport) { app.familyIndices.presentFamily = cast(uint)i; }
      if (app.familyIndices.graphicsFamily == uint.max){ app.familyIndices.graphicsFamily = cast(uint)i; }
    }
  }
  toStdout(" - app.familyIndices.presentFamily: %d", app.familyIndices.presentFamily);
  toStdout(" - app.familyIndices.graphicsFamily: %d", app.familyIndices.graphicsFamily);
}

// Create the logical device, and load the device level functions, to supplement the local and global level functions
void createLogicalDevice(ref App app){
  loadDeviceLevelFunctions(app.instance);
  app.getGraphicsQueueFamilyIndex();
  float[1] queuePriorities = [ 0.0f ];
  VkDeviceQueueCreateInfo queueCreateInfo = {
    queueCount : 1,
    pQueuePriorities : queuePriorities.ptr,
    queueFamilyIndex : app.familyIndices.graphicsFamily,
  };

  const(char)*[] deviceExtensions = [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];
  VkPhysicalDeviceFeatures deviceFeatures = {
    samplerAnisotropy: VK_FALSE
  };

  VkDeviceCreateInfo deviceCreateInfo = {
    queueCreateInfoCount : 1,
    pQueueCreateInfos : &queueCreateInfo,
    enabledExtensionCount : cast(uint)deviceExtensions.length,
    ppEnabledExtensionNames : &deviceExtensions[0],
    pEnabledFeatures: &deviceFeatures
  };

  enforceVK(vkCreateDevice(app.physicalDevices[app.selected], &deviceCreateInfo, null, &app.device));
  toStdout("Logical device %p created", app.device);
  loadDeviceLevelFunctions(app.device);
  toStdout("Device level functions loaded via device %p", app.device);
  vkGetDeviceQueue(app.device, app.familyIndices.graphicsFamily, 0, &app.graphicsQueue);
  toStdout("Logical device graphics queue obtained");
  vkGetDeviceQueue(app.device, app.familyIndices.presentFamily, 0, &app.presentQueue);
  toStdout("Logical device present queue obtained");
}
