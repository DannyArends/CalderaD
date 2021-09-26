// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.algorithm : max;
import std.path : baseName, stripExtension;
import calderad, io, texture;

/* TileAtlas for textures */
struct TileAtlas {
  int id = 0;
  int[2][string] x;
  int[2][string] y;
  string[] names;
}

float[2] lTop(TileAtlas ta, Texture t, string tname){ 
  return([to!float(ta.x[tname][0]) / to!float(t.width), to!float(ta.y[tname][0]) / to!float(t.height) ] );
}
float[2] rTop(TileAtlas ta, Texture t, string tname){
  return([to!float(ta.x[tname][1]) / to!float(t.width), to!float(ta.y[tname][0]) / to!float(t.height) ] );
}
float[2] lBot(TileAtlas ta, Texture t, string tname){
  return([to!float(ta.x[tname][0]) / to!float(t.width), to!float(ta.y[tname][1]) / to!float(t.height) ] );
}
float[2] rBot(TileAtlas ta, Texture t, string tname){
  return([to!float(ta.x[tname][1]) / to!float(t.width), to!float(ta.y[tname][1]) / to!float(t.height) ] );
}

/* create the TileAtlas for files in folder, maximum size width x height */
TileAtlas createTileAtlas(ref App app, string folder = "", int width = 512, int height = 512){
  TileAtlas tileAtlas;
  toStdout("createAtlas on: %s", toStringz(folder));
  string[] files = dir(folder);
  SDL_Surface*[string] surfaces;
  int tx, yc, row, ym = 0;
  foreach(file; files){
    string tname = stripExtension(baseName(file)).toLower();
    surfaces[tname] = IMG_Load(toStringz(file));
    tileAtlas.names ~= tname;
    if(tx + surfaces[tname].w > width){
      row = row + 1;
      yc = yc + ym;
      ym = 0;
      tx = 0;
    }
    tileAtlas.x[tname] = [tx, tx + surfaces[tname].w]; tx += surfaces[tname].w;
    tileAtlas.y[tname] = [yc, yc + surfaces[tname].h];
    ym = max(ym, surfaces[tname].h);
    //toStdout("createAtlas %s: %d [%d %d]", toStringz(tname), tx, surfaces[tname].w, surfaces[tname].h);
  }
  auto surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
  foreach(tname; tileAtlas.names) {
    //toStdout("blitSurface %s", toStringz(tname));
    SDL_Rect dstrect = {
      x: tileAtlas.x[tname][0], w: tileAtlas.x[tname][1] - tileAtlas.x[tname][0],
      y: tileAtlas.y[tname][0], h: tileAtlas.y[tname][1]
    };
    SDL_BlitSurface(surfaces[tname], null, surface, &dstrect);
    SDL_FreeSurface(surfaces[tname]); // Free the SDL_Surface
  }
  surface.toRGBA();
  auto texture = app.createTextureImage(surface);
  tileAtlas.id = texture.id;
  app.tileAtlas = tileAtlas;
  toStdout("TileAtlas created with %d elements", tileAtlas.names.length);
  return(app.tileAtlas);
}
