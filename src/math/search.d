// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.algorithm : sort, remove;
import std.array : empty;
import std.math : abs;
import std.stdio : writefln;

import calderad, map, searchnode, vector;

enum SearchState { NOT_INITIALISED = 0, SEARCHING = 1, SUCCEEDED = 2, FAILED = 3, INVALID = 4 };

/* Implementation of the search state structure */
struct Search(M, N) {
  M map; // map information structure
  N start; // start node structure
  N goal; // goal node structure
  N* pathptr; // pointer to the current node in the path
  N[] openlist; // Astar open list
  N[] closedlist; // Astar closed list
  SearchState state = SearchState.NOT_INITIALISED;
  size_t steps = 0; // search steps taken
  size_t path = 0; // step in current path
  size_t maxsteps = 150; // maximum number of search steps
  bool cancel = false; // cancels an active search
}

/* Set the start and goal node and set the state to searching */
void setStartAndGoalStates(S, M, N)(ref S search, ref M map, ref N startnode, ref N goalnode) {
  search.map = map;
  search.start = startnode;
  search.goal = goalnode;

  search.start.g = 0.0f;
  search.start.h = euclidean(startnode.position, goalnode.position);
  search.start.parent = null;

  search.state = SearchState.SEARCHING;

  search.openlist ~= search.start;
  search.pathptr = &search.start;
  search.steps = 0;

  // If the start and end are the same the search requested is not valid
  if (startnode.isEqual(goalnode)) search.state = SearchState.INVALID;
}

/* Walk backwards via the parent pointers, setting the child pointers */
void storeRoute(S, N)(ref S search, N* node){
  N* nodeChild = node;
  N* nodeParent = node.parent;
  do {
    nodeParent.child = nodeChild;
    nodeChild = nodeParent;
    nodeParent = nodeParent.parent;
  } while( !nodeChild.isEqual(&search.start) ); // Start is always the first node by definition */
  search.start = (*nodeChild);
}

/* Do a step of the A star searching algorithm */
SearchState step(S, N)(ref S search, N node = Node()) {
  // Break if the user has not initialised the search, and allow step after the search has succeeded or failed
  if (!((search.state > SearchState.NOT_INITIALISED) && (search.state < SearchState.INVALID))) {
    toStdout("Uninitialized/invalid search detected\n");
    return search.state;
  }
  if ( (search.state == SearchState.SUCCEEDED) || (search.state == SearchState.FAILED) ) return search.state;

  if ( search.openlist.empty() || search.cancel ) {  // Fail searching when there are no nodes left or the user cancels
    search.state = SearchState.FAILED;
    return search.state;
  }
  //toStdout("step: %d, lengths (open/closed): (%d/%d)\n",search.steps, search.openlist.length, search.closedlist.length);

  N* n = &search.openlist[0];  // Get the best / closest node found so far
  //toStdout("closest position so far: [%.1f, %.1f, %.1f]\n", n.x, n.y, n.z);
  search.steps++; // Take a step, generate successors list 
  if (n.isEqual(&search.goal)) {
    //toStdout("n Equal to search.goal\n");
    search.state = SearchState.SUCCEEDED;
    search.goal.parent = n.parent;
    search.storeRoute(&search.goal);
    //toStdout("storeRoute(search.goal) done\n");
    return search.state;
  } else { // n notEqual to search.goal
    //toStdout("n notEqual to search.goal\n");
    N[] successors = search.map.getSuccessors(n);
    if (successors.empty()) {
      search.state = SearchState.FAILED;
      return search.state;
    }
    foreach (ref N s; successors) {
      float newG = n.g + s.cost;
      // Find if a better path (lower g) to the node is on the open or closed list, if so, we can forget this successor
      size_t i;
      if ((i = search.openlist.has(s)) > 0 && search.openlist[i].g <= newG) {
        continue;
      }
      if ((i = search.closedlist.has(s)) > 0 && search.closedlist[i].g <= newG) {
        continue;
      }
      // No better path to this location was found, so we will just add it for later exploration
      s.parent = n;
      s.g = newG;
      s.h = euclidean(s.position, search.goal.position);
      // Remove from the closed list (if present) and update / add the node to the openlist
      if ((i = search.closedlist.has(s)) > 0) search.closedlist = search.closedlist.remove(i);
      if ((i = search.openlist.has(s)) > 0) { 
        search.openlist[i] = s;
      } else {
        search.openlist ~= s;
      }
    }
  }
  // Remove n from the openlist, and add n to the closed list re-sort by cumulative cost values to target;
  search.closedlist ~= (*n);
  search.openlist = search.openlist.remove(0);
  search.openlist.sort!("a.f < b.f")();
  return search.state;
}

/* Take a step through the path computed */
float[3] stepThroughPath(S)(ref S search) {
  float[3] p = [ search.pathptr.x, search.pathptr.y, search.pathptr.z ];
  toStdout("path %d : [%.2f, %.2f, %.2f] %f\n", search.path, p[0], p[1], p[2], search.pathptr.h);
  search.pathptr = search.pathptr.child;
  search.path++;
  return(p);
}

/* Test if the current path pointer is at the goal position */
bool atGoal(S)(const S search) {
  return(search.pathptr.isEqual(&search.goal));
}

/* Perform a search and return the result, after which the search.stepThroughPath allows to walk it */
Search!(M, N) performSearch(M, N)(float[3] start = [0.0f, 0.0f, 0.0f], 
                                  float[3] goal = [-7.0f, 15.7f, -7.2f], M map = Map()) {
  Search!(Map, Node) search;
  Node s = Node(null, start, 0.0f, 0.0f);
  Node g = Node(null, goal, 0.0f);
  search.setStartAndGoalStates(map, s, g);
  do {
    search.state = search.step();
  } while(search.state == SearchState.SEARCHING && search.steps < search.maxsteps);

  // If we're still searching, set the optimal route to be the closest one so far 
  if (search.state == SearchState.SEARCHING) {
    toStdout("SEARCHING: %s, after: %d / %d", toStringz(format("%s", search.state)), search.steps, search.maxsteps);
    search.goal = search.openlist[0];
    search.storeRoute(&search.openlist[0]);
  }
  return(search);
}

/* Perform a test search and return the result, after which search.stepThroughPath allows to walk the steps */
void testSearch() {
  // Perform a pathfinding search
  Search!(Map, Node) search = performSearch!(Map, Node)();

  // If the search was succesful or still searching is ok, we use the 'best path so far approach'
  if (search.state == SearchState.SUCCEEDED || search.state == SearchState.SEARCHING) {
    do {
      search.stepThroughPath();
    } while( !search.atGoal() ); // We can step untill we are at the end of the path
  }
}
