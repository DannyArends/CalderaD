// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, geometry, vector, vertex;

struct Square {
  Geometry geometry = {
    vertices : [ Vertex([-0.5f, 0.0f, -0.5f], [1.0f, 1.0f], [1.0f, 0.8f, 0.8f, 1.0f]), 
                 Vertex([ 0.5f, 0.0f, -0.5f], [0.0f, 1.0f], [0.8f, 1.0f, 0.8f, 1.0f]),
                 Vertex([ 0.5f, 0.0f,  0.5f], [0.0f, 0.0f], [0.8f, 0.8f, 1.0f, 1.0f]),
                 Vertex([-0.5f, 0.0f,  0.5f], [1.0f, 0.0f], [0.8f, 0.8f, 1.0f, 1.0f]) ],
    indices : [0, 2, 1, 0, 3, 2]
  };

  alias geometry this;
}

void split(Geometry g, int face = 0) {

}

struct Squares {
  Geometry geometry = {
    vertices : [ Vertex([-0.5f, 0.0f, -0.5f], [1.0f, 1.0f], [1.0f, 0.8f, 0.0f, 1.0f]), 
                 Vertex([ 0.5f, 0.0f, -0.5f], [0.0f, 1.0f], [0.8f, 0.0f, 0.8f, 1.0f]),
                 Vertex([ 0.5f, 0.0f,  0.5f], [0.0f, 0.0f], [0.0f, 0.0f, 1.0f, 1.0f]),
                 Vertex([-0.5f, 0.0f,  0.5f], [1.0f, 0.0f], [0.8f, 0.0f, 0.0f, 1.0f]),

                 Vertex([-1.0f, 0.5f, -1.0f], [1.0f, 1.0f], [1.0f, 0.8f, 0.8f, 1.0f]), 
                 Vertex([ 1.0f, 0.5f, -1.0f], [0.0f, 1.0f], [0.8f, 1.0f, 0.8f, 1.0f]),
                 Vertex([ 1.0f, 0.5f,  1.0f], [0.0f, 0.0f], [0.8f, 0.8f, 1.0f, 1.0f]),
                 Vertex([-1.0f, 0.5f,  1.0f], [1.0f, 0.0f], [0.8f, 0.8f, 1.0f, 1.0f]),

                 Vertex([-10.5f, -10.5f, 0.0f], [1.0f, 1.0f], [0.0f, 0.8f, 0.0f, 1.0f]), 
                 Vertex([ 10.5f, -10.5f, 0.0f], [0.0f, 1.0f], [0.2f, 1.0f, 0.0f, 1.0f]),
                 Vertex([ 10.5f,  10.5f, 0.0f], [0.0f, 0.0f], [0.2f, 0.8f, 0.0f, 1.0f]),
                 Vertex([-10.5f,  10.5f, 0.0f], [1.0f, 0.0f], [0.0f, 0.8f, 0.0f, 1.0f])
               ],
    indices : [0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 8, 9, 10, 10, 11, 8]
  };

  alias geometry this;
}
