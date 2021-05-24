// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.math : sqrt;

/* Convert a T[4] to a T[3] */
@nogc pure T[3] xyz(T)(const T[4] v) nothrow { 
    return([v[0], v[1], v[2]]);
}

/* Positional shortcuts for arrays */
@nogc pure T x(T)(const T[] v) nothrow { assert(v.length > 0); return(v[0]); }
@nogc pure T y(T)(const T[] v) nothrow { assert(v.length > 1); return(v[1]); }
@nogc pure T z(T)(const T[] v) nothrow { assert(v.length > 2); return(v[2]); }

/* xzy & yzx swiffle functions for T[3] vector v */
@nogc pure T[3] xzy(T)(const T[3] v) nothrow { return([v[0], v[2], v[1]]); }
@nogc pure T[3] yzx(T)(const T[3] v) nothrow { return([v[1], v[2], v[0]]); }

/* Positional shortcuts for color arrays */
@nogc pure T red(T)(const T[] v) nothrow { assert(v.length > 0); return(v[0]); }
@nogc pure T green(T)(const T[] v) nothrow { assert(v.length > 1); return(v[1]); }
@nogc pure T blue(T)(const T[] v) nothrow { assert(v.length > 2); return(v[2]); }

/* Dot product between v1 and v2 */
@nogc pure T dot(T)(const T[3] v1, const T[3] v2) nothrow {
    T[3] vDot = v1[] * v2[];
    return(sum(vDot));
}

/* Euclidean distance between v1 and v2 */
@nogc pure T euclidean(T)(const T[3] v1, const T[3] v2) nothrow {
    return sqrt( (v1[0] - v2[0]) * (v1[0] - v2[0]) + (v1[1] - v2[1]) * (v1[1] - v2[1]) + (v1[2] - v2[2]) * (v1[2] - v2[2]) );
}

/* Compute the (normalized) mid-point between v1 and v2 */
@nogc pure T[3] midpoint(T)(const T[3] v1, const T[3] v2, bool normalized = false) nothrow {
    T[3] vMean = (v1[] + v2[]) / 2.0f;
    if(normalized) vMean.normalize();
    return(vMean);
}

/* Mean of vector v */
@nogc pure T mean(T)(const T[] v) nothrow {
    return(sum(v) / cast(T)(v.length));
}

/* Sum of vector v */
@nogc pure T sum(T)(const T[] v) nothrow { 
    T sum = 0;
    for (size_t i = 0; i < v.length; i++) { sum += v[i]; }
    return(sum);
}

/* Returns the normalized vector of v */
@nogc pure T[3] normalize(T)(ref T[3] v) nothrow {
    float sqr = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
    if(sqr == 1 || sqr == 0) return(v);
    float invrt = 1.0f / sqrt(sqr);
    v[] *= invrt;
    return(v);
}

/* Get the largest containing square of two vectors */
@nogc pure T[3] containingSquare(T)(const T[3] v1, const T[3] v2) nothrow { 
    T[3] res = [ 0.0f, 0.0f, 0.0f ];
    res[0] = (v1[0] > v2[0])? v1[0] : v2[0];
    res[1] = (v1[1] > v2[1])? v1[1] : v2[1];
    res[2] = (v1[2] > v2[2])? v1[2] : v2[2];
    return res;
}

/* Cross product between vectors */
@nogc pure T[3] cross(T)(const T[3] v1, const T[3] v2) nothrow {
    T[3] res = [ 0.0f, 0.0f, 0.0f ];
    res[0] = v1[1]*v2[2] - v1[2]*v2[1];
    res[1] = v1[2]*v2[0] - v1[0]*v2[2];
    res[2] = v1[0]*v2[1] - v1[1]*v2[0];
    return res;
}

/* T[3] pass through vectorized functions for +,-,*,^ */
// vAdd: a + v(1) | v(1) + v(2)
// vMul, vDiv, vPow: b * v(1), b / v(1), v(1) * v(1)
@nogc pure T[3] vAdd(T)(const T[3] v1, const T[3] v2) nothrow {
    T[3] vAdd = v1[] + v2[]; return(vAdd);
}
@nogc pure T[3] vAdd(T)(const T[3] v, const T a) nothrow {
    T[3] vAdd = v[] + a; return(vAdd);
}
@nogc pure T[3] vSub(T)(const T[3] v1, const T[3] v2) nothrow {
    T[3] vSub = v1[] - v2[]; return(vSub);
}
@nogc pure T[3] negate(T)(ref T[3] v) nothrow {
    v[] = -v[]; return(v);
}
@nogc pure T[3] vMul(T)(const T[3] v, const T[3] b) nothrow {
    T[3] vMul = v[] * b[]; return(vMul);
}
@nogc pure T[3] vMul(T)(const T[3] v, const T b) nothrow {
    T[3] vMul = v[] * b; return(vMul);
}
@nogc pure T[3] vDiv(T)(const T[3] v, const T b) nothrow {
    T[3] vDiv = v[] / b; return(vDiv);
}
@nogc pure T[3] vPow(T)(const T[3] v) nothrow {
    T[3] vPow = v[] * v[]; return(vPow);
}
