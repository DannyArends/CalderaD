// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.string : strcmp;
import calderad;

bool checkValidationLayerSupport(ref App app, const(char*) layerName) {
  uint32_t layerCount;
  vkEnumerateInstanceLayerProperties(&layerCount, null);
  toStdout("checkValidationLayerSupport: %s, layerCount: %d", layerName, layerCount);
  if(layerCount == 0) return(false);

  VkLayerProperties[] availableLayers;
  availableLayers.length = layerCount;
  vkEnumerateInstanceLayerProperties(&layerCount, &availableLayers[0]);
  bool layerFound = false;
  foreach(layerProperties; availableLayers) {
    if (strcmp(layerName, layerProperties.layerName.ptr) == 0) {
      layerFound = true;
      break;
    }
  }
  toStdout("Layer: %s was %sfound", layerName, toStringz((layerFound? "": "not")));
  return(layerFound);
}

version (Windows) {
  extern (Windows) VkBool32 debugCallback(VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageType, const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void* pUserData) nothrow @nogc {
    toStdout("validation layer: %s", pCallbackData.pMessage); return VK_FALSE;
  }
} else { // Version not Windows uses C bindings
  extern (C) VkBool32 debugCallback(VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageType, const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void* pUserData) nothrow @nogc {
    toStdout("validation layer: %s", pCallbackData.pMessage); return VK_FALSE;
  }
}

VkResult createDebugMessenger(VkInstance instance, const VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pDebugMessenger) {
  auto fn = cast(PFN_vkCreateDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
  if (fn) return fn(instance, pCreateInfo, pAllocator, pDebugMessenger);
  return VK_ERROR_EXTENSION_NOT_PRESENT;
}

void destroyDebugMessenger(VkInstance instance, VkDebugUtilsMessengerEXT debugMessenger, const VkAllocationCallbacks* pAllocator) {
  auto fn = cast(PFN_vkDestroyDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
  if (fn) fn(instance, debugMessenger, pAllocator);
}

void setupDebugMessenger(ref App app) {
  if(!app.enableValidationLayers) return;

  VkDebugUtilsMessengerCreateInfoEXT createInfo = {
    sType: VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
    messageSeverity: VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT, // VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
    messageType: VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
    pfnUserCallback: &debugCallback
  };
  enforceVK(createDebugMessenger(app.instance, &createInfo, null, &app.debugMessenger));
}
