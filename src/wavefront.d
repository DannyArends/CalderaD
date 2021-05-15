// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.array : array, split;
import std.algorithm : map, startsWith, splitter;
import calderad, io, vertex;

struct Geometry {
  string name;
  float[3] position = [0.0f, 0.0f, 0.0f];

  Vertex[] vertices(){
    Vertex[] vtx;
    vtx.length = verts.length;
    foreach (i, pos; verts) { vtx[i] = Vertex(pos); }
    foreach (face; faces) {
      vtx[face[0]].texCoord = mapcoords[face[1]];
      vtx[face[0]].normal = normals[face[2]];
      vtx[face[0]].texCoord[1] = 1.0f - vtx[face[0]].texCoord[1];
    }
    return(vtx);
  }

  uint[] indices() {
    uint[] idx;
    idx.length = faces.length;
    foreach(i, face; faces) { idx[i] = face[0]; }
    return(idx);
  }

  int[3][] faces;
  float[3][] verts;
  float[3][] normals;
  float[2][] mapcoords;
  
  VkBuffer vertexBuffer;
  VkDeviceMemory vertexBufferMemory;

  VkBuffer indexBuffer;
  VkDeviceMemory indexBufferMemory;

  Geometry* next;
}

Geometry loadWavefront(ref App app, string path) {
  char[] content = cast(char[])readFile(path); // Open for reading
  string filecontent = to!string(content);
  foreach (line; content.split("\n")) {
    if (line.startsWith("v ")) {
      app.geometry.verts ~= line[2..$].splitter.map!(to!float).array[0 .. 3];
    }else if (line.startsWith("f ")) {
      app.geometry.faces ~= loadIndex(line);
    }else if (line.startsWith("o ")) {
      app.geometry.name ~= to!string(line[2..$]);
    }else if (line.startsWith("vt ")) {
      app.geometry.mapcoords ~= line[3..$].splitter.map!(to!float).array[0 .. 2];
    }else if (line.startsWith("vn ")) {
      app.geometry.normals ~= line[3..$].splitter.map!(to!float).array[0 .. 3];
    }
  }
  toStdout("Wavefront '%s', nVertices: %d, nFaces: %d", toStringz(path), app.geometry.vertices.length, app.geometry.indices.length);
  return(app.geometry);
}

int[3][] loadIndex(char[] line) {
  int[3][] face;
  int[3] tmp;
  foreach (pol; line[2..$].splitter) {
    auto split = pol.splitter("/").map!(to!int).array;
    tmp[0] = split[0] - 1;
    if(split.length > 1) tmp[1] = split[1] - 1;
    if(split.length > 2) tmp[2] = split[2] - 1;
    face ~= tmp;
  }
  return(face);
}
