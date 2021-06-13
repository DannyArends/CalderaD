// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, vector, matrix, vertex;

struct GeometryInstanceData { // Holds instance specific offset data
  mat4 offset = mat4.init;
};

struct Geometry {
  VkBuffer vertexBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory vertexBufferMemory = VK_NULL_ND_HANDLE;

  VkBuffer indexBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory indexBufferMemory = VK_NULL_ND_HANDLE;

  VkBuffer instanceBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory instanceBufferMemory = VK_NULL_ND_HANDLE;

  Vertex[] vertices;
  uint[] indices;
  GeometryInstanceData[] instances = [GeometryInstanceData.init]; 

  int texture = 0;
  mat4 filemodel = mat4.init; // Model is there to correct for file format up/orientation differences (3DS, MTL, WaveFront)

  Geometry* next;
}
