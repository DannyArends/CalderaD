import std.conv;
import std.string;
import bindbc.sdl;
import erupted;

import application, buffer, log, wavefront;

uint[] readFile(App app, string path) {
  SDL_RWops *rw = SDL_RWFromFile(toStringz(path), "rb");
  if (rw == null){
    SDL_Log("readFile: couldn't open file '%s'\n", toStringz(path));
    return [];
  }
  uint[] res;
  auto res_size = SDL_RWsize(rw);

  res.length = cast(size_t)res_size;
  size_t nb_read_total = 0, nb_read = 1;
  uint* cpos = &res[0];
  while (nb_read_total < res_size && nb_read != 0) {
    nb_read = SDL_RWread(rw, cpos, 1, cast(size_t)(res_size - nb_read_total));
    nb_read_total += nb_read;
    cpos += nb_read;
  }
  SDL_RWclose(rw);
  if (nb_read_total != res_size) SDL_Log("readFile: loaded %db, expected %db\n", nb_read_total, res_size);
  SDL_Log("Loaded %d bytes\n", nb_read_total);
  return res;
}