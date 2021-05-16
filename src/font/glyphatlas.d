// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.utf : isValidDchar;
import calderad, glyph, texture;

struct GlyphAtlas {
    string path;
    TTF_Font* ttf;
    ubyte size;
    Glyph[dchar] glyphs;
    ushort[] atlas;
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

GlyphAtlas loadGlyphAtlas(string filename, ubyte size = 12, uint width = 1024) {
  GlyphAtlas font = GlyphAtlas(filename);
  font.size = (size == 0)? 12 : size;
  font.ttf = TTF_OpenFont(toStringz(filename), font.size);
  if (!font.ttf) {
    SDL_Log("Error by loading TTF_Font %s: %s\n", toStringz(filename), TTF_GetError());
    return(font);
  }
  font.atlas = font.createGlyphAtlas();
  return(font);
}

// Populates the GlyphAtlas with Glyphs to dchar in our atlas
ushort[] createGlyphAtlas(ref GlyphAtlas font, uint width = 1024) {
  int i, t, atlasrow, atlasloc, w, h;
  ushort[] atlas = [];
  dchar c = '\u0000';
  auto max_width = 1024;
  width = (width > max_width)? max_width : width;
  while (c <= '\U00000FFF') {
    if (isValidDchar(c) && TTF_GlyphIsProvided(font.ttf, cast(ushort)(c)) && !(c == '\t' || c == '\r' || c == '\n')) {
      Glyph glyph = Glyph();
      TTF_GlyphMetrics(font.ttf, cast(ushort)(c), &glyph.minx, &glyph.maxx, &glyph.miny, &glyph.maxy, &glyph.advance);
      if (atlasloc + glyph.advance >= width) {
        atlas ~= cast(ushort)('\n');
        i = 0;
        atlasloc = 0;
        atlasrow++;
      }
      if (font.advance < glyph.advance) font.advance = glyph.advance;
      if (font.miny > glyph.miny) font.miny = glyph.miny;
      glyph.atlasloc = atlasloc;
      glyph.atlasrow = atlasrow;
      font.glyphs[c] = glyph;
      atlas ~= cast(ushort)(c);
      atlasloc += glyph.advance;
      i++;
    }
    t++; c++;
  }
  TTF_SizeUNICODE(font.ttf, atlas.ptr, &w, &h);
  toStdout("%d unicode glyphs (%d unique ones)\n", atlas.length, font.glyphs.length);
  toStdout("FontAscent: %d\n", TTF_FontAscent(font.ttf));
  toStdout("FontAdvance: %d\n", font.advance);
  font.height = h; // Use height from TTF_SizeUNICODE, since TTF_FontHeight reports it wrong for some fonts
  font.ascent = TTF_FontAscent(font.ttf);
  toStdout("%d/%d unicode glyphs on %d lines\n", font.glyphs.length, t, ++atlasrow);
  return(atlas);
}
