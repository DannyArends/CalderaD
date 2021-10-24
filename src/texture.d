// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.string : memcpy;
import calderad, buffer, glyphatlas, images, io, log;

/*
  Texture application structure, aliasses the SDL_Surface
  Stores texture related Vulkan variables
*/
struct Texture {
  int width = 0;
  int height = 0;
  int id = 0;

  VkImage textureImage;
  VkDeviceMemory textureImageMemory;
  VkImageView textureImageView;

  SDL_Surface* surface;
  alias surface this;
}

// Load all texture files matching pattern in folder
void loadTextures(ref App app, string folder, string pattern = "*.{png,jpg}") {
  string[] files = dir(folder, pattern);
  foreach(file; files){ app.createTextureImage(file); }
}

// Create the TextureImage from GlyphAtlas surface
void createTextureImage(ref App app, ref GlyphAtlas glyphatlas) {
  app.glyphatlas.texture = app.createTextureImage(glyphatlas.surface, "[FONT]");
}

// Create the TextureImage from a file using IMG_Load
Texture createTextureImage(ref App app, string filename) {
  auto surface = IMG_Load(toStringz(filename));
  return(app.createTextureImage(surface, filename));
}

// Convert an SDL-Surface to RGBA32 format
void toRGBA(ref SDL_Surface* surface) {
  SDL_PixelFormat *fmt = SDL_AllocFormat(SDL_PIXELFORMAT_RGBA32);
  fmt.BitsPerPixel = 32;
  SDL_Surface* adapted = SDL_ConvertSurface(surface, fmt, 0);
  SDL_FreeFormat(fmt); // Free the SDL_PixelFormat
  if (adapted) {
    SDL_FreeSurface(surface); // Free the SDL_Surface
    surface = adapted;
    toStdout("surface adapted: %p [%dx%d:%d]", surface, surface.w, surface.h, (surface.format.BitsPerPixel / 8));
  }
}

// Create a TextureImage layout and view from the SDL_Surface and adds it to the App.textureArray
Texture createTextureImage(ref App app, SDL_Surface* surface, string name = "DEFAULT") {
  toStdout("surface obtained: %p [%dx%d:%d]", surface, surface.w, surface.h, (surface.format.BitsPerPixel / 8));

  if (surface.format.BitsPerPixel != 32) {
    surface.toRGBA();
  } else { toStdout("surface was 32 bits not adapted"); }

  Texture texture = { width: surface.w, height: surface.h, surface: surface };
  VkBuffer stagingBuffer;
  VkDeviceMemory stagingBufferMemory;
  app.createBuffer(
    imageSize(surface), VK_BUFFER_USAGE_TRANSFER_SRC_BIT, 
    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, 
    &stagingBuffer, &stagingBufferMemory
  );
  void* data;
  vkMapMemory(app.device, stagingBufferMemory, 0, imageSize(surface), 0, &data);
  memcpy(data, surface.pixels, cast(size_t)(imageSize(surface)));
  vkUnmapMemory(app.device, stagingBufferMemory);
  app.createImage(
    surface.w, surface.h, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_TILING_OPTIMAL, 
    VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    &texture.textureImage, &texture.textureImageMemory
  );

  app.transitionImageLayout(texture.textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

  app.copyBufferToImage(stagingBuffer, texture.textureImage, surface.w, surface.h);

  app.transitionImageLayout(texture.textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

  texture.textureImageView = app.createImageView(texture.textureImage, VK_FORMAT_R8G8B8A8_SRGB);

  toStdout("Adding texture %s at [%d]", toStringz(name), to!int(app.textureArray.length));
  texture.id = to!int(app.textureArray.length);
  app.textureArray ~= texture;

  toStdout("Freeing surface: %p [%dx%d:%d]", surface, surface.w, surface.h, (surface.format.BitsPerPixel / 8));
  SDL_FreeSurface(surface);
  vkDestroyBuffer(app.device, stagingBuffer, null);
  vkFreeMemory(app.device, stagingBufferMemory, null);
  return(app.textureArray[($-1)]);
}

// Create a TextureSampler for sampling from a texture
void createTextureSampler(ref App app) {
  VkPhysicalDeviceProperties properties = {};
  VkPhysicalDeviceFeatures supportedFeatures = {};

  vkGetPhysicalDeviceProperties(app.physicalDevices[app.selected], &properties);
  vkGetPhysicalDeviceFeatures(app.physicalDevices[app.selected], &supportedFeatures);

  VkSamplerCreateInfo samplerInfo = {
    sType: VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
    magFilter: VK_FILTER_LINEAR,
    minFilter: VK_FILTER_LINEAR,
    addressModeU: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    addressModeV: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    addressModeW: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    anisotropyEnable: ((supportedFeatures.samplerAnisotropy) ? VK_FALSE : VK_TRUE),
    maxAnisotropy: properties.limits.maxSamplerAnisotropy,
    borderColor: VK_BORDER_COLOR_INT_OPAQUE_BLACK,
    unnormalizedCoordinates: VK_FALSE,
    compareEnable: VK_FALSE,
    compareOp: VK_COMPARE_OP_ALWAYS,
    mipmapMode: VK_SAMPLER_MIPMAP_MODE_LINEAR,
    mipLodBias: 0.0f,
    minLod: 0.0f,
    maxLod: 0.0f
  };
  
  enforceVK(vkCreateSampler(app.device, &samplerInfo, null, &app.textureSampler));
}

