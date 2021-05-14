// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import vector : x,y,z;

/* Create a T[3], w as a T[4] */
@nogc pure T[4] xyzw(T)(const T[3] v, T w = 1.0f) nothrow {
    return([v.x, v.y, v.z, w]);
}

/* Create a T[3], alpha as a T[4] */
@nogc pure T[4] rgba(T)(const T[3] v, T a = 1.0f) nothrow {
    return([v.red, v.green, v.blue, a]);
}

/* Positional shortcuts for quaternion */
@nogc pure T w(T)(const T[] v) nothrow { assert(v.length > 3); return(v[3]); }
@nogc pure T alpha(T)(const T[] v) nothrow { assert(v.length > 3); return(v[3]); }

/* T[4] math pass through vectorized functions for +,-,*,^ */
// vAdd: a + v(1) | v(1) + v(2)
// vMul, vDiv, vPow: b * v(1), b / v(1), v(1) * v(1)
@nogc pure T[4] vAdd(T)(const T[4] v1, const T[4] v2) nothrow {
    T[4] vAdd = v1[] + v2[]; return(vAdd);
}
@nogc pure T[4] vAdd(T)(const T[4] v1, const T a) nothrow {
    T[4] vAdd = v1[] + a; return(vAdd);
}
@nogc pure T[4] vSub(T)(const T[4] v1, const T[4] v2) nothrow {
    T[4] vSub = v1[] - v2[]; return(vSub);
}
@nogc pure T[4] negate(T)(ref T[4] v) nothrow {
    v[] = -v[]; return(v);
}
@nogc pure T[4] vMul(T)(const T[4] v1, const T[4] v2) nothrow {
    T[4] vMul = v1[] * v2[]; return(vMul);
}
@nogc pure T[4] vMul(T)(const T[4] v1, const T b) nothrow {
    T[4] vMul = v1[] * b; return(vMul);
}
@nogc pure T[4] vDiv(T)(const T[4] v1, const T b) nothrow {
    T[4] vDiv = v1[] / b; return(vDiv);
}
@nogc pure T[4] vPow(T)(const T[4] v1) nothrow {
    T[4] vPow = v1[] * v1[]; return(vPow);
}
