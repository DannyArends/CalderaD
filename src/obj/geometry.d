// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, vector, matrix, pushconstant, vertex;

struct GeometryInstanceData { // Holds instance specific offset data
  mat4 offset = mat4.init;
};

struct Geometry {
  // Vulkan vertex, index and indices bufferhandles
  VkBuffer vertexBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory vertexBufferMemory = VK_NULL_ND_HANDLE;

  VkBuffer indexBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory indexBufferMemory = VK_NULL_ND_HANDLE;

  VkBuffer instanceBuffer = VK_NULL_ND_HANDLE;
  VkDeviceMemory instanceBufferMemory = VK_NULL_ND_HANDLE;

  // Push constants
  int texture = 0;  // Texture
  mat4 filemodel = mat4.init; // Model is there to correct for file format up/orientation differences (3DS, MTL, WaveFront)

  // Vertices, indices and instances
  Vertex[] vertices;
  uint[] indices;
  GeometryInstanceData[] instances = [GeometryInstanceData.init]; 

  Geometry* next; // TODO: unused
}

// Draws geometry[j] to buffer[i]
void draw(ref App app, size_t i, size_t j) {
  VkDeviceSize[] offsets = [0];

  PushConstant pc = {
    oId: to!int(j),
    tId: app.geometry[j].texture,
    model: app.geometry[j].filemodel
  };
  vkCmdPushConstants(app.commandBuffers[i], app.pipeline.pipelineLayout, 
                     VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0, 
                     PushConstant.sizeof, &pc);

  vkCmdBindVertexBuffers(app.commandBuffers[i], VERTEX_BUFFER_BIND_ID, 1, &app.geometry[j].vertexBuffer, &offsets[0]);
  vkCmdBindVertexBuffers(app.commandBuffers[i], INSTANCE_BUFFER_BIND_ID, 1, &app.geometry[j].instanceBuffer, &offsets[0]);

  vkCmdBindIndexBuffer(app.commandBuffers[i], app.geometry[j].indexBuffer, 0, VK_INDEX_TYPE_UINT32);

  vkCmdBindDescriptorSets(app.commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, app.pipeline.pipelineLayout, 0, 1, &app.descriptor.descriptorSets[app.geometry[j].texture], 0, null);

  vkCmdDrawIndexed(app.commandBuffers[i], cast(uint)app.geometry[j].indices.length, cast(uint)app.geometry[j].instances.length, 0, 0, 0);
}
