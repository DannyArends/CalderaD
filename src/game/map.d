// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, geometry, search, searchnode, tileatlas, vector, vertex;

enum ObjectType { NONE = 0, TILE = 1 };

struct Object {
  Node node;
  alias node this;
  ObjectType type = ObjectType.NONE;
  string name = "tilenone";
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
  foreach(pos; map.objects.keys){
    foreach(obj; map.objects[pos]){
      if(obj.type == ObjectType.TILE){
        map.geometry.vertices ~= Vertex([pos.x-size, pos.y-size, pos.z], rBot(app.tileAtlas, app.textureArray[app.tileAtlas.id], obj.name), [1.0f, 1.0f, 1.0f, 1.0f]); 
        map.geometry.vertices ~= Vertex([pos.x+size, pos.y-size, pos.z], lBot(app.tileAtlas, app.textureArray[app.tileAtlas.id], obj.name), [1.0f, 1.0f, 1.0f, 1.0f]);
        map.geometry.vertices ~= Vertex([pos.x+size, pos.y+size, pos.z], lTop(app.tileAtlas, app.textureArray[app.tileAtlas.id], obj.name), [1.0f, 1.0f, 1.0f, 1.0f]);
        map.geometry.vertices ~= Vertex([pos.x-size, pos.y+size, pos.z], rTop(app.tileAtlas, app.textureArray[app.tileAtlas.id], obj.name), [1.0f, 1.0f, 1.0f, 1.0f]);
        map.geometry.indices ~= [cnt+0, cnt+2, cnt+1, cnt+0, cnt+3, cnt+2];
        cnt += 4;
      }
    }
  }
}

Map generateMap(string seed = "CalderaD"){
  Map map;
  
  for(float z = -10; z < 10; z += 0.25) {
    for(float x = -15; x < 15; x += 1) {
      for(float y = -15; y < 15; y += 1) {
        string name = "notile";
        if(z <= -5) name = "lava";
        if(z >= -6 && z <= -5) name = "gravel1";
        if(z >= -5 && z <= 0) name = "mud1";
        if(z >= -2 && z <= 0) name = "sand1";
        if(z >= 0 && z <= 2) name = "grass1";
        if(z >= 2) name = "water3";
        if(z >= 5) name = "ice";
        Node n = {position: [x, y, z]};
        Object tile = { node: n, type: ObjectType.TILE, name : name };
        map.objects[n.position] = [tile];
  }}}
  toStdout("generateMap tiles = %d", map.objects.length);
  return(map);
}

void testGenMap(ref App app){
  app.map = generateMap();
  Search!(Map, Node) search = performSearch!(Map, Node)([0.0f, 0.0f, 0.0f], [5.0f, 10.0f, -2.0f], app.map);
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
    if(obj.type == ObjectType.TILE) return(true);
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
float cost(M)(const M map, const float[3] position) {
  float cost = 0.1f;
  return cost;
}
