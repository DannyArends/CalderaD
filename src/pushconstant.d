// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, matrix;

struct PushConstant {
  mat4 model;
  int oId; // object id
  int tId; // textureSamplers index
}
