// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad;

struct Camera {
    float[3]     position    = [-3.0f, -3.0f, 0.5f];  // Position
    float[3]     lookat      = [0.0f, 0.0f, 0.0f];    // Position in the middle of the screen
    float[2]     nearfar     = [0.1f, 100.0f];        // View distances, near [0], far [1]
    float[3]     up          = [0.0f, 0.0f, 1.0f];    // Defined up vector
    float        fov         = 45.0f;                 // Field of view
}
