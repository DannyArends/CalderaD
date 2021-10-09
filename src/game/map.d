// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.random : choice, uniform;
import std.algorithm : min;
import std.math : round, ceil;
import calderad, square, geometry, search, searchnode, tileatlas, vector, vertex;

struct Object {
  Node node;
  uint index;
  uint vert;
  alias node this;
  TileType type = TileType.None;
}

/* Implementation of M abstract class
   should provide the functions: getSuccessors() and cost() */
struct Map {
  Object[][float[3]] objects;
  Geometry geometry;
  float tilesize;
  alias geometry this;
}

size_t nobjects(const Map map) {
  size_t cnt = 0;
  foreach(p; map.objects.keys){
    foreach(obj; map.objects[p]){
      cnt++;
    }
  }
  return(cnt);
}

int nTiles(float[3][3] dim = [[-30, 30, 1.0f],[-30, 30, 1.0f],[-10, 10, 0.25f]]){
  int nx = 1 + to!int(ceil((dim[0][1] - dim[0][0]) * 1.0f / dim[0][2])); // from and including so + 1
  int ny = 1 + to!int(ceil((dim[1][1] - dim[1][0]) * 1.0f / dim[1][2]));
  int nz = 1 + to!int(ceil((dim[2][1] - dim[2][0]) * 1.0f / dim[2][2]));
  //toStdout("Generating: %dx%dx%d = %d", nx, ny, nz, (nx * ny * nz));
  return((nx * ny * nz));
}

Map generateMap(ref App app, string seed = "CalderaD", 
                float[3][3] dim = [[-15, 15, 1.0f],[-20, 15, 1.0f],[-5, 10, 0.25f]], 
                float size = 0.5) {
  int icnt = 0, vcnt = 0; // Current start indices, vertices
  app.map.tilesize = size;
  int nTile = nTiles(dim); // Total number of tiles
  toStdout("Generating: %s, number of tiles: %d", toStringz(seed), nTile);
  app.map.geometry.vertices.length = nTile * 4;
  app.map.geometry.indices.length = nTile * 6;
  for(float z = dim[2][0]; z <= dim[2][1]; z += dim[2][2]) {
    for(float x = dim[0][0]; x <= dim[0][1]; x += dim[0][2]) {
      for(float y = dim[1][0]; y <= dim[1][1]; y += dim[1][2]) {
        TileType type = TileType.None;
        if(z <= -5) type = choice([TileType.Lava, TileType.Gravel1]);
        if(z >= -6 && z <= -5) type = TileType.Gravel1;
        if(z >= -5 && z <= -2) type = choice([TileType.Mud1, TileType.Gravel1, TileType.Sand1]);
        if(z >= -2 && z <= 0) type = choice([TileType.Mud1, TileType.Sand1, TileType.Sand2]);
        if(z >= 0 && z <= 2) type = choice([TileType.Grass1, TileType.Grass2, TileType.Forestfloor1, TileType.Forestfloor2]);
        if(z >= 2 && z <= 2.5) type = choice([TileType.Water1, TileType.Water2, TileType.Water3, TileType.Water4]);
        if(z >= 5) type =  choice([TileType.Air, TileType.None]);
        Node n = {position: [x, y, z]};
        Object tile = { node: n, type: type, index: icnt, vert: vcnt };
        app.map.objects[tile.node.position] = [tile];
        app.updateTile(tile, x, y, z, app.map.tilesize);
        vcnt += 4;
        icnt += 6;
  }}}

  toStdout("generateMap tiles = %d, v = %d, i = %d", app.map.objects.length, app.map.geometry.vertices.length, app.map.geometry.indices.length);
  int tcnt = 0;
  int niter = 100;
  for(int i = 0; i < niter; i++){
    int xp = uniform(-15, 15);
    int xw = uniform(1, 25);
    int yp = uniform(-15, 15);
    int yw = uniform(1, 25);
    tcnt += app.updateColumn(app.map, [xp, min(xw, 25)], [yp, min(yw, 25)], app.map.tilesize);
  }
  toStdout("Updated %d tiles in %d loops", tcnt, niter);
  return(app.map);
}

void updateTile(ref App app, Object tile, float cx, float cy, float z, float size = 0.5f){
  float up = 0.0f;
  float[4] color = [1.0f, 1.0f, 1.0f, 1.0f];
  if(tile.type == TileType.Air){ up = 15.0f; color = [1.0f, 1.0f, 1.0f, 0.0f]; size = uniform(0.1f, 0.7f); }
  if(tile.type == TileType.None){ color = [0.0f, 0.0f, 0.0f, 1.0f]; size = 0.01f; }

  auto square = Square(
    [ [cx-size, cy-size, z+up], [cx+size, cy-size, z+up], [cx+size, cy+size, z+up], [cx-size, cy+size, z+up]],
      [rBot(app, tile.type.name), lBot(app, tile.type.name), lTop(app, tile.type.name), rTop(app, tile.type.name)],
      [color, color, color, color]
    );
  app.map.geometry.vertices[tile.vert .. (tile.vert + 4)] = square.vertices;
  app.map.geometry.indices[tile.index .. (tile.index + 6)] = [tile.vert + 0, tile.vert + 2, tile.vert + 1, tile.vert + 0, tile.vert + 3, tile.vert + 2];
}

int updateColumn(ref App app, ref Map map, float[2] xr, float[2] yr, float size = 0.5){
  //toStdout("update column: ");
  int cnt = 0;
  for(float x = xr[0]; x <= xr[1]; x += 1) {
    for(float y = yr[0]; y <= yr[1]; y += 1) {
      if(uniform(0.0f,1.0f) > 0.1){
        cnt += app.moveUp(map, x, y, size);
      }else{
        cnt += app.moveDown(map, x, y, size);
      }
    }
  }
  return(cnt);
}

int moveUp(ref App app, ref Map map, float cx, float cy, float size = 0.5) {
  int cnt = 0;
  TileType type = TileType.Lava;
  for(float z = -10; z <= 10; z += 0.25f) {
    foreach(ref obj; map.getObjectsAt([cx, cy, z])){
      TileType old = obj.type;
      obj.type = type;
      type = old;//choice([old, type]);
      cnt++;
      if(z > 4 && (obj.type == TileType.Water1 || obj.type == TileType.Water2 || obj.type == TileType.Water3 || obj.type == TileType.Water4)){
        obj.type = TileType.None;
        type = TileType.None;
      }
      app.updateTile(obj, cx, cy, z, size);
    }
  }
  return(cnt);
}

int moveDown(ref App app, ref Map map, float cx, float cy, float size = 0.5) {
  int cnt = 0;
  TileType type = TileType.None;
  for (float z = 10; z >= -10; z -= 0.25f) {
    foreach (ref obj; map.getObjectsAt([cx, cy, z])){
      TileType old = obj.type;
      obj.type = type;
      type = old;//choice([old, type]);
      cnt++;
      app.updateTile(obj, cx, cy, z, size);
    }
  }
  return(cnt);
}

Object[] getObjectsAt(Map map, float[3] pos) nothrow {
  auto p = (pos in map.objects);
  if (p !is null) {
    return(map.objects[pos]);
  }
  return([]);
}


TileType getTileType(const Map map, float[3] pos){
  auto p = (pos in map.objects);
  if (p !is null) {
    foreach(t; map.objects[pos]) {
      if(t.type != TileType.None) return(t.type);
    }
  }
  return(TileType.None);
}

void testGenMap(ref App app){
  app.map = app.generateMap();

  // Test the search 100 times, to make sure we find a path or fail (correctly)
  for(int x = 0; x < 10; x++) {
    float[3] from = [uniform(-15, 15), uniform(-5, 5), uniform(-3, 5)];
    float[3] to = [uniform(-15, 15), uniform(-5, 5), uniform(-3, 5)];
  
    Search!(Map, Node) search = performSearch!(Map, Node)(from, to, app.map);
    // If the search was succesful, failed or still searching is ok, we use the 'best path so far approach'
    toStdout("Search: %s:%s %s:%s = %s", toStringz(format("%s", from)), toStringz(format("%s", getTileType(app.map, from))), toStringz(format("%s", to)), toStringz(format("%s", getTileType(app.map, to))), toStringz(format("%s", search.state)));
    if (search.state == SearchState.SUCCEEDED || search.state == SearchState.SEARCHING) {
      do {
        search.stepThroughPath(false);
      } while( !search.atGoal() ); // We can step untill we are at the end of the path
    }
  }
}

bool isTile(const Map map, float[3] node){
  //toStdout("isTile: %f %f %f == %d",node[0],node[1],node[2], (node in map.objects));
  if((node in map.objects) is null) return(false);
  foreach(obj; map.objects[node]){
    if(obj.type != TileType.None && obj.type.traverable) return(true);
  }
  return(false);
}

/* Get the successor nodes (reachable positions) of a node, we could use larger step-sizes 
   to allow for fine-grained adjustment by having the map to perform a cost-adjustment based on it */
N[] getSuccessors(M, N)(const M map, N* parent, float[] stepsizes = [-1.0f, 1.0f]) {
  N[] successors;
  float[3] to;
  foreach (size_t d; [0, 1, 2]) {
    foreach (float v; stepsizes) {
      to = parent.position;
      to[d] += v;
      //toStdout("getSuccessors: %d, [%f, %f, %f]", map.isTile(to),to[0],to[1],to[2]);
      if (map.isTile(to)) {
        successors ~= N(parent, to, map.cost(to));
      }
    }
  }
  //toStdout("Node at [%.1f, %.1f, %.1f] has %d successors\n", parent.x, parent.y, parent.z, successors.length);
  return(successors);
}

/* Cost function for including a certain map position */
float cost(M)(const M map, const float[3] node) {
  float cost = 0.1f;
  if((node in map.objects) is null) cost = 999.0f;
  foreach(obj; map.objects[node]){
    if(obj.type != TileType.None && obj.type.traverable) cost = 0.1 * obj.type.cost;
  }
  //toStdout("Cost: %f, [%f, %f, %f]", cost,node[0],node[1],node[2]);
  return cost;
}
