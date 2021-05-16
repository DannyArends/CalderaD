// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, geometry, vertex;

struct Square {
  Geometry geometry = {
    vertices : [ Vertex([-0.5f, -0.5f, 0.0f], [1.0f, 1.0f], [1.0f, 0.8f, 0.8f]), 
                 Vertex([ 0.5f, -0.5f, 0.0f], [0.0f, 1.0f], [0.8f, 1.0f, 0.8f]),
                 Vertex([ 0.5f,  0.5f, 0.0f], [0.0f, 0.0f], [0.8f, 0.8f, 1.0f]),
                 Vertex([-0.5f,  0.5f, 0.0f], [1.0f, 0.0f], [0.8f, 0.8f, 1.0f]) ],
    indices : [0, 1, 2, 2, 3, 0]
  };

  alias geometry this;
}
