// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import core.stdc.string : memcpy;
import std.math;
import calderad, buffer, glyphatlas, images, log;

struct Texture {
  int width = 0;
  int height = 0;

  VkImage textureImage;
  VkDeviceMemory textureImageMemory;
  VkImageView textureImageView;

  SDL_Surface* surface;
  alias surface this;
}


/* isPow2 and newtPow2 helper functions */
@nogc bool isPow2(uint val) nothrow { return(nextPow2(val) == val); }
@nogc uint nextPow2(uint val) nothrow { return(cast(uint)(pow(2, ceil(log2(val))))); }

/* Resize a texture to be a power of 2 */
void toPow2(ref SDL_Surface* surface) nothrow {
    if (!surface) return;
    uint reqW, reqH = 0;
    uint bpp = surface.pitch / surface.w;
    toStdout("Resize Texture original %dx%d:%d (%d)\n", surface.w, surface.h, bpp, surface.pitch);
    reqW = (isPow2(surface.w))? surface.w : nextPow2(surface.w);
    reqH = (isPow2(surface.h))? surface.h : nextPow2(surface.h);
    toStdout("Resize Texture target %dx%d:%d\n", reqW, reqH, bpp);
    uint[] data = new uint[](reqW * bpp * reqH);
    SDL_LockSurface(surface);
    uint* image = cast(uint*) surface.pixels;
    size_t nbuf = 0;
    for (size_t y = 0; y < surface.h; y++) {
      size_t from = (y * surface.w);
      size_t to = (y * surface.w) + surface.w;
      if(!y) toStdout("Resize - copy [%d:%d]\n", from, to);
      data[from .. to] = image[from .. to];
      nbuf++;
    }
    toStdout("Resize texture copied %d buffers\n", nbuf);
    SDL_UnlockSurface(surface);
    SDL_Surface* adapted = SDL_CreateRGBSurfaceFrom(cast(void*)data.ptr, reqW, reqH, bpp * 8, reqW * bpp,
                                                 surface.format.Rmask,
                                                 surface.format.Gmask,
                                                 surface.format.Bmask,
                                                 surface.format.Amask);
    //SDL_FreeSurface(surface); // Free the SDL_Surface
    surface = adapted;
    toStdout("Resize texture surface updated\n");
}

void createTextureImage(ref App app, ref GlyphAtlas glyphatlas) {
  app.glyphatlas.texture = app.createTextureImage(glyphatlas.surface);
}

Texture createTextureImage(ref App app, string filename) {
  auto surface = IMG_Load(toStringz(filename));
  return(app.createTextureImage(surface));
}

void toRGBA(ref SDL_Surface* surface){
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

Texture createTextureImage(ref App app, SDL_Surface* surface) {
  toStdout("surface obtained: %p [%dx%d:%d]", surface, surface.w, surface.h, (surface.format.BitsPerPixel / 8));

  if (surface.format.BitsPerPixel != 32) {
    surface.toRGBA();
  }else{
    toStdout("Surface not adapted");
  }

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

  toStdout("Freeing surface: %p [%dx%d:%d]", surface, surface.w, surface.h, (surface.format.BitsPerPixel / 8));
  SDL_FreeSurface(surface);
  vkDestroyBuffer(app.device, stagingBuffer, null);
  vkFreeMemory(app.device, stagingBufferMemory, null);

  app.textureArray ~= texture;
  return(app.textureArray[($-1)]);
}

void createTextureSampler(ref App app) {
  VkPhysicalDeviceProperties properties = {};
  vkGetPhysicalDeviceProperties(app.physicalDevices[app.selected], &properties);

  VkSamplerCreateInfo samplerInfo = {
    sType: VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
    magFilter: VK_FILTER_LINEAR,
    minFilter: VK_FILTER_LINEAR,
    addressModeU: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    addressModeV: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    addressModeW: VK_SAMPLER_ADDRESS_MODE_REPEAT,
    anisotropyEnable: VK_TRUE,
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

