// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, glyph, texture;

struct GlyphAtlas {
    string path;
    TTF_Font* ttf;
    ubyte size;
    Glyph[dchar] glyphs;
    Texture texture;
    int height;
    int ascent;
    int miny;
    int advance;

    Glyph* getGlyph(dchar letter) nothrow {
      if(letter in glyphs) return(&glyphs[letter]);
      return(&(glyphs.values[0]));
    }

    @property @nogc float tX(Glyph* glyph) nothrow { 
      return((glyph.atlasloc + glyph.minx) / cast(float)(this.texture.width));
    }

    @property @nogc float tY(Glyph* glyph) nothrow {
      int lineHsum = (this.height) * glyph.atlasrow;
      return((lineHsum + (this.ascent - glyph.maxy)) / cast(float)(this.texture.height));
    }

    @property @nogc float pX(Glyph* glyph, size_t col) nothrow {
      return(cast(float)(col) * glyph.advance + glyph.minx);
    }

    @property @nogc float pY(Glyph* glyph, size_t[2] row) nothrow {
      return(cast(float)(row[1] - row[0]) * (this.height) + glyph.miny - this.miny);
    }
}
