// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad;

void pickPhysicalDevice(ref App app, uint select = 0) {
  uint pDevicetype = 0;
  vkEnumeratePhysicalDevices(app.instance, &app.nPhysDevices, null);
  toStdout("Number of physical vulkan devices found: %d", app.nPhysDevices);
  app.physicalDevices.length = app.nPhysDevices;
  vkEnumeratePhysicalDevices(app.instance, &app.nPhysDevices, &app.physicalDevices[0]);
  if(select > app.nPhysDevices) select = 0;

  foreach(i, physDevice; app.physicalDevices) {
    VkPhysicalDeviceProperties properties;
    vkGetPhysicalDeviceProperties(physDevice, &properties);
    toStdout("-Physical device %d: %s", i, properties.deviceName.ptr);
    toStdout("|- API Version: %d.%d.%d", VK_API_VERSION_MAJOR(properties.apiVersion), VK_API_VERSION_MINOR(properties.apiVersion), VK_API_VERSION_PATCH(properties.apiVersion));
    toStdout("|- Image sizes: (1D/2D/3D) %d %d %d", properties.limits.maxImageDimension1D, properties.limits.maxImageDimension2D, properties.limits.maxImageDimension3D);
    toStdout("|- Max PushConstantSize: %d", properties.limits.maxPushConstantsSize);
    toStdout("|- Max MemoryAllocationCount: %d", properties.limits.maxMemoryAllocationCount);
    toStdout("|- Max ImageArrayLayers: %d", properties.limits.maxImageArrayLayers);
    toStdout("|- Max SamplerAllocationCount: %d", properties.limits.maxSamplerAllocationCount);
    toStdout("|- Device type: %d", properties.deviceType);
    if(i > select && properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU && pDevicetype == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU) {
      toStdout("|- Switching to from integrated to discrete GPU device: %d", (i+1));
      select = cast(uint)i;
    }
    pDevicetype = properties.deviceType;
  }
  app.selected = select;
  toStdout("Physical device %d from %d selected", (app.selected + 1), app.physicalDevices.length);
}
