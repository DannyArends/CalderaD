// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.random : choice, uniform;
import std.algorithm : min;
import calderad, square, geometry, search, searchnode, tileatlas, vector, vertex;

struct Object {
  Node node;
  alias node this;
  TileType type = TileType.None;
}

/* Implementation of M abstract class
   should provide the functions: getSuccessors() and cost() */
struct Map {
  Object[][float[3]] objects;
  Geometry geometry;
  alias geometry this;
}

void createGeometry(ref App app, ref Map map, float size = 0.5){
  int cnt = 0;
  foreach(p; map.objects.keys){
    foreach(obj; map.objects[p]){
      if(obj.type != TileType.None){
        //Cube cube;
        Square square = Square(
        [ [p.x-size, p.y-size, p.z], [p.x+size, p.y-size, p.z], [p.x+size, p.y+size, p.z], [p.x-size, p.y+size, p.z]],
          [rBot(app, obj.type.name), lBot(app, obj.type.name), lTop(app, obj.type.name), rTop(app, obj.type.name)]
        );
        map.geometry.vertices ~= square.vertices;
        map.geometry.indices ~= [cnt+0, cnt+2, cnt+1, cnt+0, cnt+3, cnt+2];
        cnt += 4;
      }
    }
  }
}

Map generateMap(string seed = "CalderaD"){
  Map map;
  
  for(float z = -10; z <= 10; z += 0.25f) {
    for(float x = -25; x <= 25; x += 1) {
      for(float y = -25; y <= 25; y += 1) {
        TileType type = TileType.None;
        if(z <= -5) type = choice([TileType.Lava,TileType.Gravel1]);
        if(z >= -6 && z <= -5) type = TileType.Gravel1;
        if(z >= -5 && z <= -2) type = choice([TileType.Mud1, TileType.Gravel1, TileType.Sand1]);
        if(z >= -2 && z <= 0) type = choice([TileType.Mud1, TileType.Sand1, TileType.Sand2]);
        if(z >= 0 && z <= 2) type = choice([TileType.Grass1, TileType.Grass2, TileType.Forestfloor1, TileType.Forestfloor2]);
        if(z >= 2 && z <= 2.5) type = choice([TileType.Water1, TileType.Water2, TileType.Water3, TileType.Water4]);
        if(z >= 5) type = TileType.None;
        Node n = {position: [x, y, z]};
        Object tile = { node: n, type: type };
        map.objects[n.position] = [tile];
  }}}
  toStdout("generateMap tiles = %d", map.objects.length);
  int cnt = 0;
  int niter = 195;
  for(int i = 0; i < niter; i++){
    int xp = uniform(-15, 15);
    int xw = uniform(1, 25);
    int yp = uniform(-15, 15);
    int yw = uniform(1, 25);
    cnt += map.updateColumn([xp, min(xw, 25)], [yp, min(yw, 25)]);
  }
  toStdout("updated %d tiles in %d loops", cnt, niter);
  return(map);
}

int updateColumn(ref Map map, float[2] xr, float[2] yr){
  //toStdout("update column: ");
  int cnt = 0;
  for(float x = xr[0]; x <= xr[1]; x += 1) {
    for(float y = yr[0]; y <= yr[1]; y += 1) {
      if(uniform(0.0f,1.0f) > 0.1){
        cnt += map.moveUp(x,y);
      }else{
        cnt += map.moveDown(x,y);
      }
    }
  }
  return(cnt);
}

int moveUp(ref Map map, float cx, float cy) nothrow {
  int cnt = 0;
  TileType type = TileType.Lava;
  for(float z = -10; z <= 10; z += 0.25f) {
    foreach(ref obj; map.objects[[cx, cy, z]]){
      TileType old = obj.type;
      obj.type = type;
      type = old;//choice([old, type]);
      cnt++;
      if(z > 4 && (obj.type == TileType.Water1 || obj.type == TileType.Water2 || obj.type == TileType.Water3 || obj.type == TileType.Water4)){
        obj.type = TileType.None;
        type = TileType.None;
      }
    }
  }
  return(cnt);
}

int moveDown(ref Map map, float cx, float cy) nothrow {
  int cnt = 0;
  TileType type = TileType.None;
  for(float z = 10; z >= -10; z -= 0.25f) {
    foreach(ref obj; map.objects[[cx, cy, z]]){
      TileType old = obj.type;
      obj.type = type;
      type = old;//choice([old, type]);
      cnt++;
    }
  }
  return(cnt);
}


void testGenMap(ref App app){
  app.map = generateMap();
  Search!(Map, Node) search = performSearch!(Map, Node)([0.0f, 0.0f, 0.0f], [5.0f, 13.0f, 4.0f], app.map);
    // If the search was succesful or still searching is ok, we use the 'best path so far approach'
  if (search.state == SearchState.SUCCEEDED || search.state == SearchState.SEARCHING) {
    do {
      search.stepThroughPath();
    } while( !search.atGoal() ); // We can step untill we are at the end of the path
  }else{
    toStdout("SearchState error: %s", toStringz(format("%s", search.state)));
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
