// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, vector;

/* Implementation of N abstract class
   should provide a custom isEqual function and the has function using custom isEqual */
struct Node {
  Node* parent; // used during the search to record the parent of successor nodes
  float[3] position = [0.0f, 0.0f, 0.0f]; // Position of the node
  float cost = 1.0f; // cost of the node
  float g; // cost of this node + it's predecessors
  float h; // heuristic estimate of distance to goal
  // sum of cumulative cost of this node + predecessors + heuristic
  @nogc @property float f() nothrow const { return(this.g + this.h); }
  Node* child; // used after the search for the application to view the search in reverse

  @nogc @property float x() nothrow const { return(this.position[0]); }
  @nogc @property float y() nothrow const { return(this.position[1]); }
  @nogc @property float z() nothrow const { return(this.position[2]); }
}

/* isEqual is just based on euclidean proximity, when the euclidean distance < 0.10f then 2 nodes equal */
bool isEqual(N)(const N x, const N y) {
  if (euclidean(x.position, y.position) < 0.10f) return true;
  return false;
}

/* Uses the isEqual function to determine the index of a node is in the open / closed list
   when not found returns 0 as the index */
size_t has(N)(N[] array, N x) {
  foreach (size_t i, N e; array) {
    if (e.isEqual(x)) return i;
  }
  return(0);
}
