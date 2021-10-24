// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html
import std.math : sqrt, PI, atan;
import calderad, geometry, vector, vertex;

const float x = 0.426943;
const float y = 0.904279;

struct Icosahedron {
  Geometry geometry = {
    vertices : [ 
                 Vertex([-x, y,0], toTC([-x, y,0]), [1.0f, 1.0f, 1.0f, 1.0f]), 
                 Vertex([ x, y,0], toTC([ x, y,0]), [1.0f, 1.0f, 1.0f, 1.0f]),
                 Vertex([-x,-y,0], toTC([-x,-y,0]), [1.0f, 0.8f, 1.0f, 1.0f]),
                 Vertex([ x,-y,0], toTC([ x,-y,0]), [1.0f, 0.8f, 1.0f, 1.0f]),
                                                            
                 Vertex([0,-x, y], toTC([0,-x, y]), [1.0f, 1.0f, 1.0f, 1.0f]), 
                 Vertex([0, x, y], toTC([0, x, y]), [1.0f, 1.0f, 1.0f, 1.0f]),
                 Vertex([0,-x,-y], toTC([0,-x,-y]), [1.0f, 1.0f, 1.0f, 1.0f]),
                 Vertex([0, x,-y], toTC([0, x,-y]), [1.0f, 1.0f, 1.0f, 1.0f]),
                                                            
                 Vertex([ y,0,-x], toTC([ y,0,-x]), [1.0f, 1.0f, 1.0f, 1.0f]), 
                 Vertex([ y,0, x], toTC([ y,0, x]), [1.0f, 1.0f, 1.0f, 1.0f]),
                 Vertex([-y,0,-x], toTC([-y,0,-x]), [1.0f, 1.0f, 1.0f, 1.0f]),
                 Vertex([-y,0, x], toTC([-y,0, x]), [1.0f, 1.0f, 1.0f, 1.0f])
               ],
    indices : [0, 11, 5, 0,  5,  1,  0,  1,  7,  0, 7, 10, 0, 10, 11,
               1,  5, 9, 5, 11,  4, 11, 10,  2, 10, 7,  6, 7,  1,  8,
               3,  9, 4, 3,  4,  2,  3,  2,  6,  3, 6,  8, 3,  8,  9,
               4,  9, 5, 2,  4, 11,  6,  2, 10,  8, 6,  7, 9,  8,  1]
  };
  alias geometry this;
}

float[2] toTC(float[3] p) nothrow {
    float normalisedX =  0.0f;
    float normalisedZ = -1.0f;
    float xSq = p[0] * p[0];
    float zSq = p[2] * p[2];
    if ((xSq + zSq) > 0.0f) {
      normalisedX = sqrt(xSq / (xSq + zSq));
      normalisedZ = sqrt(zSq / (xSq + zSq));
      if (p[0] < 0.0f) normalisedX = -normalisedX;
      if (p[2] < 0.0f) normalisedZ = -normalisedZ;
    }
    float[2] texCoord = [0.0f, (-p[1] + 1.0f) / 2.0f];
    if (normalisedZ == 0.0f) {
      texCoord[0] = ((normalisedX * PI) / 2.0f);
    } else {
      texCoord[0] = atan(normalisedX / normalisedZ);
    }
    if (normalisedZ < 0.0f)  texCoord[0] += PI;
    if (texCoord[0] < 0.0f)  texCoord[0] += 2.0f * PI;      // Shift U coordinate between 0-2pi

    texCoord[0] /= (2.0f * PI);                             // Normalize U coordinate range 0-2pi -> 0, 1
    return(texCoord);
}