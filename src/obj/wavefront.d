// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.array : array, split;
import std.algorithm : map, startsWith, splitter;
import calderad, io, geometry, vertex;

struct WaveFront {
  string name;
  int[3][] faces; // faces holds the objects: [vertex index = 0, mapcoords index = 1, normal index = 2]
  float[3][] verts; // per vertex position x,y,z
  float[3][] normals; // per vertex normals x,y,z
  float[2][] mapcoords; // per vertex texture mapcoords x,y,z

  Vertex[] createVertices(){
    geometry.vertices.length = verts.length;
    foreach (i, pos; verts) { geometry.vertices[i] = Vertex(pos); }
    foreach (face; faces) {
      geometry.vertices[face[0]].texCoord = mapcoords[face[1]];
      geometry.vertices[face[0]].texCoord[1] = 1.0f - geometry.vertices[face[0]].texCoord[1];
      geometry.vertices[face[0]].normal = normals[face[2]];
    }
    return(geometry.vertices);
  }

  uint[] createIndices() {
    geometry.indices.length = faces.length;
    foreach(i, face; faces) { geometry.indices[i] = face[0]; }
    return(geometry.indices);
  }

  Geometry geometry = { texture: 1 }; // WaveFront model uses texture 1 by default (fontatlas should be at 0)
  alias geometry this;
}

// Loads a wavefront obj file into a geometry
// TODO: Update the geometry texture value based on file content
WaveFront loadWavefront(ref App app, string path) {
  char[] content = cast(char[])readFile(path); // Open for reading
  string filecontent = to!string(content);
  WaveFront obj = WaveFront();
  foreach (line; content.split("\n")) {
    if (line.startsWith("v ")) {
      obj.verts ~= line[2..$].splitter.map!(to!float).array[0 .. 3];
    }else if (line.startsWith("f ")) {
      obj.faces ~= loadIndex(line);
    }else if (line.startsWith("o ")) {
      obj.name ~= to!string(line[2..$]);
    }else if (line.startsWith("vt ")) {
      obj.mapcoords ~= line[3..$].splitter.map!(to!float).array[0 .. 2];
    }else if (line.startsWith("vn ")) {
      obj.normals ~= line[3..$].splitter.map!(to!float).array[0 .. 3];
    }
  }
  obj.createVertices();
  obj.createIndices();
  toStdout("Wavefront '%s', nVertices: %d, nFaces: %d", toStringz(path), obj.vertices.length, obj.indices.length);
  return(obj);
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
