// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, geometry, glyph, glyphatlas, vertex;

int[2] getSize(GlyphAtlas atlas, const char* text){
  int[2] size;
  TTF_SizeText(atlas.ttf, text, &size[0], &size[1]);
  return(size);
}

struct Text {
  Geometry geometry = { };

  this(GlyphAtlas atlas, string value = "Hellow World", float scale = 0.3f){
    float glyphscale = (1.0f/scale) * cast(float)(atlas.pointsize);
    toStdout("GlyphAtlas: %d, %d, %d, %d, %d", atlas.width, atlas.height, atlas.ascent, atlas.miny, atlas.advance);
    ulong[2] row = [1, 1];
    foreach(uint i, dchar c; value.array) {
      auto cChar = atlas.getGlyph(c);
      //toStdout("Glyph[%d|%c] = i:[%d,%d]", c, c, cChar.atlasloc, cChar.atlasrow);
      //toStdout("Glyph[%d|%c] = g:[%d,%d]", c, c, cChar.gX, cChar.gY);
      //toStdout("Glyph[%d|%c] = t:[%.4f,%.4f]", c, c, atlas.tX(cChar), atlas.tY(cChar));
      // Convert everything to Glyphscale (based on the chosen fontsize)
      float pX = atlas.pX(cChar, i) /  glyphscale;
      float pY = atlas.pY(cChar, row) /  glyphscale;
      float w = cChar.gX / glyphscale;
      float h = cChar.gY / glyphscale;
      float tXo = cChar.gX / cast(float)(atlas.surface.w);
      float tYo = cChar.gY / cast(float)(atlas.surface.h);
      //toStdout("Glyph[%d|%c] = p:[%.2f,%.2f]", c, c, pX, pY);
      //toStdout("Glyph[%d|%c] = pO:[%d,%d]", c, c, cChar.gX, cChar.gY);
      //toStdout("Glyph[%d|%c] = wh:[%.2f,%.2f]", c, c, w, h);
      vertices ~=
               [ Vertex([   pX, 0.0f,   pY], [atlas.tX(cChar), atlas.tY(cChar)+ tYo], [1.0f, 0.1f, 0.8f, 1.0f]), 
                 Vertex([ w+pX, 0.0f,   pY], [atlas.tX(cChar)+ tXo, atlas.tY(cChar)+ tYo], [0.0f, 1.0f, 0.0f, 1.0f]),
                 Vertex([ w+pX, 0.0f, h+pY], [atlas.tX(cChar)+ tXo, atlas.tY(cChar)], [0.0f, 0.1f, 1.0f, 1.0f]),
                 Vertex([   pX, 0.0f, h+pY], [atlas.tX(cChar), atlas.tY(cChar)], [1.0f, 0.0f, 0.0f, 1.0f])
               ];
      indices ~= [(i*4)+0, (i*4)+2, (i*4)+1, (i*4)+0, (i*4)+3, (i*4)+2];
    }

  }
  alias geometry this;
}