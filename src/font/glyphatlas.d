// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.datetime : MonoTime;
import std.utf : isValidDchar;
import calderad, glyph, texture;

// The GlyphAtlas structure holds links to the TTF_Font, Glyphs, Texture and the atlas
struct GlyphAtlas {
    string path;
    TTF_Font* ttf; // Pointer to the loaded TTF_Font
    ubyte pointsize; // Font size
    Glyph[dchar] glyphs; // associative array couples Glyph and dchar
    ushort[] atlas; // ushort array of chars which were valid and stored into the atlas (\n for linebreaks)
    SDL_Surface* surface; // Holds the SDL surface with the atlas
    Texture texture; // Holds the SDL surface with the atlas
    int width;
    int height;
    int ascent;
    int miny;
    int advance;

    Glyph* getGlyph(dchar letter) nothrow {
      if(letter in glyphs) return(&glyphs[letter]);
      return(&(glyphs.values[0]));
    }

    @property @nogc float tX(Glyph* glyph) nothrow { 
      return((glyph.atlasloc + glyph.minx) / cast(float)(surface.w));
    }

    @property @nogc float tY(Glyph* glyph) nothrow {
      int lineHsum = (this.height) * glyph.atlasrow;
      return((lineHsum + (this.ascent - glyph.maxy)) / cast(float)(surface.h));
    }

    @property @nogc float pX(Glyph* glyph, size_t col) nothrow {
      return(cast(float)(col) * glyph.advance + glyph.minx);
    }

    @property @nogc float pY(Glyph* glyph, size_t[2] row) nothrow {
      return(cast(float)(row[1] - row[0]) * (this.height) + glyph.miny - this.miny);
    }
}

// Loads a GlyphAtlas from file
GlyphAtlas loadGlyphAtlas(string filename, ubyte pointsize = 12, dchar to = '\U00000FFF', uint width = 1024, uint max_width = 1024) {
  GlyphAtlas glyphatlas = GlyphAtlas(filename);
  glyphatlas.pointsize = (pointsize == 0)? 12 : pointsize;
  glyphatlas.ttf = TTF_OpenFont(toStringz(filename), glyphatlas.pointsize);
  if (!glyphatlas.ttf) {
    toStdout("Error by loading TTF_Font %s: %s\n", toStringz(filename), TTF_GetError());
    return(glyphatlas);
  }
  glyphatlas.atlas = glyphatlas.createGlyphAtlas(to, width, max_width);
  return(glyphatlas);
}

// Populates the GlyphAtlas with Glyphs to dchar in our atlas
ushort[] createGlyphAtlas(ref GlyphAtlas glyphatlas, dchar to = '\U00000FFF', uint width = 1024, uint max_width = 1024) {
  MonoTime sT = MonoTime.currTime;
  int i, atlasrow, atlasloc, w, h;
  ushort[] atlas = [];
  dchar c = '\U00000000';
  glyphatlas.width = (width > max_width)? max_width : width;
  while (c <= to) {
    if (isValidDchar(c) && TTF_GlyphIsProvided(glyphatlas.ttf, cast(ushort)(c)) && !(c == '\t' || c == '\r' || c == '\n')) {
      Glyph glyph = Glyph();
      TTF_GlyphMetrics(glyphatlas.ttf, cast(ushort)(c), &glyph.minx, &glyph.maxx, &glyph.miny, &glyph.maxy, &glyph.advance);
      if (atlasloc + glyph.advance >= width) {
        atlas ~= cast(ushort)('\n');
        i = 0;
        atlasloc = 0;
        atlasrow++;
      }
      if (glyphatlas.advance < glyph.advance) glyphatlas.advance = glyph.advance;
      if (glyphatlas.miny > glyph.miny) glyphatlas.miny = glyph.miny;
      glyph.atlasloc = atlasloc;
      glyph.atlasrow = atlasrow;
      glyphatlas.glyphs[c] = glyph;
      atlas ~= cast(ushort)(c);
      atlasloc += glyph.advance;
      i++;
    }
    c++;
  }
  TTF_SizeUNICODE(glyphatlas.ttf, &atlas[0], &w, &h);
  toStdout("%d unicode glyphs (%d unique ones)\n", atlas.length, glyphatlas.glyphs.length);
  toStdout("FontAscent: %d\n", TTF_FontAscent(glyphatlas.ttf));
  toStdout("FontAdvance: %d\n", glyphatlas.advance);
  glyphatlas.height = h; // Use height from TTF_SizeUNICODE, since TTF_FontHeight reports it wrong for some glyphatlas
  glyphatlas.ascent = TTF_FontAscent(glyphatlas.ttf);
  glyphatlas.surface = TTF_RenderUNICODE_Blended_Wrapped(glyphatlas.ttf, &atlas[0], SDL_Color(255, 255, 255, 255), glyphatlas.width);
  MonoTime cT = MonoTime.currTime;
  auto time = (cT - sT).total!"msecs"();  // Update the current time
  toStdout("%d/%d unicode glyphs on %d lines in %d msecs\n", glyphatlas.glyphs.length, c, ++atlasrow, time);
  return(atlas);
}
