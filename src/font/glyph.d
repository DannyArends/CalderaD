// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

// Basic glyph structure
struct Glyph {
  int minx;
  int maxx;
  int miny;
  int maxy;
  int advance;
  int atlasloc;
  int atlasrow;

  @property @nogc int gX() nothrow { return(advance - minx); }
  @property @nogc int gY() nothrow { return(maxy - miny); }
}
