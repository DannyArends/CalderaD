// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import bindbc.sdl;
import erupted;

import application, log;

struct Surface {
  VkSurfaceKHR surface;
  VkSurfaceCapabilitiesKHR capabilities;
  VkSurfaceFormatKHR[] surfaceformats;
  VkPresentModeKHR[] presentModes;
  alias surface this;
}

Surface createSurface(ref App app) {
  toStdout("createSurface()");
  SDL_Vulkan_CreateSurface(app.ptr, app.instance, &app.surface);
  toStdout("SDL error?: '%s'", SDL_GetError()); // Printing to see if no errors occured
  toStdout("SDL Vulkan Surface %p created", app.surface.surface);
  return(app.surface);
}

void loadSurfaceCapabilities(ref App app) {
  uint formatCount;
  uint presentModeCount;
  enforceVK(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(app.physicalDevices[app.selected], app.surface, &app.surface.capabilities));  // Capabilities

  // Surface formats
  vkGetPhysicalDeviceSurfaceFormatsKHR(app.physicalDevices[app.selected], app.surface, &formatCount, null);
  app.surface.surfaceformats.length = formatCount;
  enforceVK(vkGetPhysicalDeviceSurfaceFormatsKHR(app.physicalDevices[app.selected], app.surface, &formatCount, &app.surface.surfaceformats[0]));

  // Surface present modes
  vkGetPhysicalDeviceSurfacePresentModesKHR(app.physicalDevices[app.selected], app.surface, &presentModeCount, null);
  app.surface.presentModes.length = presentModeCount;
  vkGetPhysicalDeviceSurfacePresentModesKHR(app.physicalDevices[app.selected], app.surface, &presentModeCount, &app.surface.presentModes[0]);

  toStdout("formatCount: %d, presentModeCount: %d", formatCount, presentModeCount);
}
