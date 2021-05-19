// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.conv;
import std.string;

import calderad, buffer, wavefront;

/* Load a file using SDL2 */
uint[] readFile(string path) {
  SDL_RWops *rw = SDL_RWFromFile(toStringz(path), "rb");
  if (rw == null){
    toStdout("readFile: couldn't open file '%s'\n", toStringz(path));
    return [];
  }
  uint[] res;

  res.length = cast(size_t)SDL_RWsize(rw);
  size_t nb_read_total = 0, nb_read = 1;
  uint* cpos = &res[0];
  while (nb_read_total < res.length && nb_read != 0) {
    nb_read = SDL_RWread(rw, cpos, 1, cast(size_t)(res.length - nb_read_total));
    nb_read_total += nb_read;
    cpos += nb_read;
  }
  SDL_RWclose(rw);
  if (nb_read_total != res.length) toStdout("readFile: loaded %db, expected %db\n", nb_read_total, res.length);
  toStdout("Loaded %d bytes\n", nb_read_total);
  return res;
}
