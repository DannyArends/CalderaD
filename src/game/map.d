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
  
  for(float z = -1; z < 1; z += 0.05) {
    for(float x = -1.5; x < 1.5; x += 0.1) {
      for(float y = -1.5; y < 1.5; y += 0.1) {
        string name = "notile";
        if(z <= -0.5) name = "lava";
        if(z >= -0.6 && z <= -0.5) name = "gravel1";
        if(z >= -0.5 && z <= 0) name = "mud1";
        if(z >= -0.2 && z <= 0) name = "sand1";
        if(z >= 0 && z <= 0.2) name = "grass1";
        if(z >= 0.2) name = "water3";
        if(z >= 0.5) name = "ice";
        Node n = {position: [15 + x*10, y*10, z-3]};
        Object tile = { node: n, type: ObjectType.TILE, name : name };
        map.objects[n.position] = [tile];
  }}}
  toStdout("generateMap tiles = %d", map.objects.length);
  return(map);
}

Map generateMapOld(){
  Map map;

  Node n1 = {position: [0.0f, 0.0f, 0.0f]};
  Object startTile = { node: n1, type: ObjectType.TILE, name : "grass1" };
  map.objects[n1.position] = [startTile];

  Node n2 = {position: [0.25f, 0.25f, 0.0f]};
  Object midTile1 = { node: n2, type: ObjectType.TILE, name : "sand1" };
  map.objects[n2.position] = [midTile1];

  Node n3 = {position: [0.0f, 0.25f, 0.25f]};
  Object midTile2 = { node: n3, type: ObjectType.TILE, name : "water1" };
  map.objects[n3.position] = [midTile2];

  Node n4 = {position: [0.0f, 0.25f, 0.0f]};
  Object endTile = { node: n4, type: ObjectType.TILE, name : "grass2" };
  map.objects[n4.position] = [endTile];

  return(map);
}

void testGenMap(ref App app){
  app.map = generateMap();
  Search!(Map, Node) search = performSearch!(Map, Node)([0.0f, 0.0f, 0.0f], [0.0f, 0.25f, 0.25f], app.map);
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
  if((node in map.objects) is null) return(false);
  foreach(obj; map.objects[node]){
    if(obj.type == ObjectType.TILE) return(true);
  }
  return(false);
}

/* Get the successor nodes (reachable positions) of a node, we could use larger step-sizes 
   to allow for fine-grained adjustment by having the map to perform a cost-adjustment based on it */
N[] getSuccessors(M, N)(const M map, N* parent, float[] stepsizes = [-0.25f, 0.25f]) {
  N[] successors;
  float[3] to;
  foreach (size_t d; [0, 1, 2]) {
    foreach (float v; stepsizes) {
      to = parent.position;
      to[d] += v;
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
