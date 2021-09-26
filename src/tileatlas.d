// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.algorithm : max;
import std.path : baseName, stripExtension;
import calderad, io, texture;

/* Basic tile type to texture mapping, name is the filename lowercased */
struct TileT {
    string name = "tilenone";
    bool traverable = false;
    float cost = 0.0f;
}

/* Define some basic tiles, traversabily and movement costs */
enum TileType : TileT {
  None = TileType("tilenone", false, 0.0),
  Asphalt = TileType("asphalt", true, 1.0),
  Forestfloor1 = TileType("forestfloor1", true, 1.5),
  Forestfloor2 = TileType("forestfloor2", true, 1.7),
  Grass1 = TileType("grass1", true, 1.2),
  Grass2 = TileType("grass2", true, 1.2),
  Gravel1 = TileType("gravel1", true, 1.6),
  Ice = TileType("ice", true, 1.0),
  Lava = TileType("lava", false, 0.0),
  Mud1 = TileType("mud1", true, 1.9),
  Roof = TileType("roof", true, 3.0),
  Sand1 = TileType("sand1", true, 1.5),
  Sand2 = TileType("sand2", true, 1.7),
  Snow1 = TileType("snow1", true, 1.6),
  Water1 = TileType("water1", true, 2.0),
  Water2 = TileType("water2", true, 2.0),
  Water3 = TileType("water3", true, 3.0),
  Water4 = TileType("water4", false, 0.0)
}

/* TileAtlas for textures */
struct TileAtlas {
  int id = 0;
  int[2][string] x;
  int[2][string] y;
  string[] names;
}

float[2] lTop(App app, string tname){ // Helper function lTop: corresponds to u,v 0,0
  TileAtlas ta = app.tileAtlas; Texture t = app.textureArray[app.tileAtlas.id];
  return([to!float(ta.x[tname][0]) / to!float(t.width), to!float(ta.y[tname][0]) / to!float(t.height) ] );
}
float[2] rTop(App app, string tname){ // Helper function rTop: corresponds to u,v 0,1
  TileAtlas ta = app.tileAtlas; Texture t = app.textureArray[app.tileAtlas.id];
  return([to!float(ta.x[tname][1]) / to!float(t.width), to!float(ta.y[tname][0]) / to!float(t.height) ] );
}
float[2] lBot(App app, string tname){ // Helper function lBot: corresponds to u,v 1,0
  TileAtlas ta = app.tileAtlas; Texture t = app.textureArray[app.tileAtlas.id];
  return([to!float(ta.x[tname][0]) / to!float(t.width), to!float(ta.y[tname][1]) / to!float(t.height) ] );
}
float[2] rBot(App app, string tname){ // Helper function rBot: corresponds to u,v 1,1
  TileAtlas ta = app.tileAtlas; Texture t = app.textureArray[app.tileAtlas.id];
  return([to!float(ta.x[tname][1]) / to!float(t.width), to!float(ta.y[tname][1]) / to!float(t.height) ] );
}

/* Create the TileAtlas for files in folder, maximum size width x height
   - First load all the surfaces
   - Blit them to an output texture surface
*/
TileAtlas createTileAtlas(ref App app, string folder = "", int width = 512, int height = 512){
  TileAtlas tileAtlas;
  toStdout("createAtlas on: %s", toStringz(folder));
  string[] files = dir(folder);
  SDL_Surface*[string] surfaces;
  int tx, yc, row, ym = 0; // texture x and current ycoord, row number and max y encountered
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
