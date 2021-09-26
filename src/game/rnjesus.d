// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.random;

import calderad;

char[6] v = ['a', 'e', 'i', 'o', 'u', 'y'];
char[21] c = ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 
              'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z'];

/* Random vowel from ['a', 'e', 'i', 'o', 'u', 'y'] with probability p */
char vowel(float[6] p = [0.20, 0.50, 0.15, 0.20, 0.10, 0.05]){
  return(v[dice(p)]);
}

/* Random consonant from 
   ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z'] 
   with probability p */
char consonant(float[21] p = [0.05,0.10,0.15,0.05,0.05,0.15,0.10,0.15,0.15,0.15,
                              0.20,0.10,0.01,0.15,0.15,0.20,0.05,0.04,0.01,0.01,0.01]){
  return(c[dice(p)]);
}

/* Random vowel from ['a', 'e', 'i', 'o', 'u', 'y'] with probability p */
char randomLetter(float[2] p = [0.55,0.45]){
  char[2] l = [vowel(),consonant()];
  return(l[dice(p)]);
}

//[[1,5], [5,1], [5,1], [1,5]] 
//[[5,1], [1,5]]
char[] randomSyllable(float[2][] p){
  char[] syl;
  syl.length = p.length;
  for(size_t x = 0; x < syl.length; x++){
    syl[x] = randomLetter(p[x]);
  }
  return(syl);
}


/*[
    [[1,50], [50,1]], // Pattern
    [[1,50], [50,1]], // Pattern
    [[1,50], [50,1], [50,1], [1,50]]
  ]*/
char[] randomWord(float[2][][] p){
  char[] w;
  for(size_t x = 0; x < p.length; x++){
    w ~= randomSyllable(p[x]);
  }
  return(w);
}

char[] randomName(float[2][][][] p){
  char[] w;
  for(size_t x = 0; x < p.length; x++){
    w ~= randomWord(p[x]) ~ " ";
  }
  return(w);
}
void testRandomNames(App app){
  for(size_t x = 0; x < 4; x++){
    char[] s1 = randomName([
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [99,1], [1,99]] // Pattern: consonant vowel vowel consonant
    ],
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [1,99], [99,1], [1,99]] // Pattern: consonant vowel consonant vowel consonant
    ]
    ]);

    char[] s2 = randomName([
    [
      [[50,50], [100,0]], // Pattern: vowel|consonant vowel
      [[50,50], [99,1], [1,99]] // Pattern: vowel|consonant vowel consonant
    ],
    [
      [[1,99], [99,1], [1,99], [99,1], [99,1]] // Pattern: consonant vowel consonant
    ],
    [
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1]], // Pattern: consonant vowel
      [[1,99], [99,1], [1,99]] // Pattern: consonant vowel consonant vowel consonant
    ]
    ]);
    toStdout("%s", toStringz(format("%s", s1)));
    toStdout("%s", toStringz(format("%s", s2)));
  }
}
