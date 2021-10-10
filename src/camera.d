// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.math;
import calderad, quaternion, vector, matrix;

struct Camera {
    float[3]     position    = [-1.0f, 0.0f, 0.0f];  // Position
    float[3]     lookat      = [0.0f, 0.0f, 0.0f];    // Position in the middle of the screen
    float[2]     nearfar     = [0.1f, 100.0f];        // View distances, near [0], far [1]
    float[3]     up          = [0.0f, 0.0f, 1.0f];    // Defined up vector
    float        fov         = 45.0f;                 // Field of view

    float[3]     rotation    = [180.0f, 0.0f, 0.0f];    // Horizontal [0], Vertical [1]
    float        distance    = -1.0f;                 // Distance of camera to lookat
    
    bool[2]      isdrag        = [false, false];

    // Move the camera forward
    @property @nogc pure float[3] forward() const nothrow { 
      float[3] direction = rotation.direction();
      direction[2] = 0.0f;
      direction.normalize();
      direction = direction.vMul(0.1f);
      return(direction);
    }

    // Move the camera backward
    @property @nogc pure float[3] back() const nothrow { 
      float[3] back = -forward()[];
      return(back);
    }

    // Move the camera to the left of the view direction
    @property @nogc pure float[3] left() const nothrow {
      float[3] direction = forward();
      float[3] left = multiply(rotate(Matrix.init, [-90.0f, 0.0f, 0.0f]), direction.xyzw()).xyz;
      return(left);
    }

    // Move the camera to the right of the view direction
    @property @nogc pure float[3] right() const nothrow { 
      float[3] right = -left()[];
      return(right);
    }
}

/* Get the normalized direction of the xy camera rotation (gimbal lock) */
@nogc pure float[3] direction(const float[3] rotation) nothrow {
    float[3] direction = [
        cos(radian(rotation[1])) * cos(radian(rotation[0])),
        cos(radian(rotation[1])) * sin(radian(rotation[0])),
        sin(radian(rotation[1]))
    ];
    direction.normalize();
    direction.negate();
    return(direction);
}

@nogc void move(ref Camera camera, float[3] movement) nothrow {
    camera.lookat = vAdd(camera.lookat, movement);
    camera.position = vAdd(camera.lookat, vMul(camera.rotation.direction(), camera.distance));
    //toStdout("%s", toStringz(format("%s", camera.position)));
    //toStdout("%s", toStringz(format("%s", camera.lookat)));
}

/* Drag the camera in the x/y directions, causes camera rotation */
@nogc void drag(ref Camera camera, float xrel, float yrel) nothrow {
    camera.rotation[0] -= xrel; 
    if(camera.rotation[0]  > 360) camera.rotation[0] = 0;
    if(camera.rotation[0]  < 0) camera.rotation[0] = 360;

    camera.rotation[1] += yrel;
    if(camera.rotation[1]  > 65) camera.rotation[1] = 65;
    if(camera.rotation[1]  < -65) camera.rotation[1] = -65;

    camera.move([0.0f, 0.0f, 0.0f]);
}
