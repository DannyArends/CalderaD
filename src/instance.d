// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.string;

import calderad;

void createInstance(ref App app) {
  VkInstanceCreateInfo instanceInfo = { 
    VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
    enabledExtensionCount: cast(uint)(app.instanceExtensions.length),
    ppEnabledExtensionNames: &app.instanceExtensions[0],
    pApplicationInfo: &app.info
  };

  if (app.enableValidationLayers) {
    instanceInfo.enabledLayerCount = cast(uint)(app.validationLayers.length);
    instanceInfo.ppEnabledLayerNames = &app.validationLayers[0];
  }

  enforceVK(vkCreateInstance(&instanceInfo, null, &app.instance));
  toStdout("Vulkan Instance created: %p", app.instance);
  loadInstanceLevelFunctions(app.instance);
  toStdout("Instance level functions loaded");
}

const(char)*[] loadInstanceExtensions(ref App app) {
  uint nExtensions;
  toStdout("loading InstanceExtensions");
  SDL_Vulkan_GetInstanceExtensions(app, &nExtensions, null);
  app.instanceExtensions.length = nExtensions;
  SDL_Vulkan_GetInstanceExtensions(app, &nExtensions, &app.instanceExtensions[0]);

  if (app.enableValidationLayers) {
    app.instanceExtensions.length = nExtensions + app.enableValidationLayers;
    app.instanceExtensions[($-1)] = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
  }
  toStdout("Number of instance extensions: %d", nExtensions);
  foreach(i, extension; app.instanceExtensions) { toStdout("- %s", extension); }
  return(app.instanceExtensions);
}
