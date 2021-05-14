// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import bindbc.sdl;

@nogc void toStdout(A...)(const string fmt, auto ref A args) nothrow {
  SDL_Log(fmt.ptr, args);
}

