// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, vertex;

struct Geometry {
  VkBuffer vertexBuffer;
  VkDeviceMemory vertexBufferMemory;

  VkBuffer indexBuffer;
  VkDeviceMemory indexBufferMemory;

  Vertex[] vertices;
  uint[] indices;

  int texture = 0;

  Geometry* next;
}
