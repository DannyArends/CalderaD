// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.math : PI, sin, cos;
import vector, quaternion;

struct Matrix { /* Matrix[4x4] structure, defaults to identity matrix */
    float[16] data = [
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 1.0f ];
  alias data this;
}

alias Matrix mat4;

/* Radian to degree, -180 .. 0 .. 180 */
@nogc pure float degree(float rad) nothrow { return rad * (180.0f / PI); }
/* Degree to radian, -180 .. 0 .. 180 */
@nogc pure float radian(float deg) nothrow {return (deg * PI) / 180.0f; }
/* Matrix x Matrix */
@nogc pure Matrix multiply(const Matrix m1, const Matrix m2) nothrow {
    Matrix res;
    float[4] v1;
    for (size_t row = 0; row < 4; ++row) {
      size_t offset = row * 4;
      v1 = m1[offset .. offset + 4];
      for (size_t col = 0; col < 4; ++col) {
        res[offset + col] = v1.vMul([ m2[col + 0], m2[col + 4], m2[col + 8], m2[col + 12] ]).sum();
      }
    }
    return res;
}

/* Matrix x V3 */
@nogc pure float[3] multiply(const Matrix m, const float[3] v) nothrow {
    return(m.multiply(v.xyzw()).xyz());
}

/* Matrix x V4 */
@nogc pure float[4] multiply(const Matrix m, const float[4] v) nothrow {
    float[4] res;
    for (size_t i = 0; i < 4; ++i) {
      res[i] = v.vMul([ m[i + 0], m[i + 4], m[i + 8], m[i + 12] ]).sum();
    }
    return res;
}

/* Matrix x Yaw, Pitch, Roll vector in degrees V(x, y, z) */
@nogc pure Matrix rotate(const Matrix m, const float[3] v) nothrow {
  float α = radian(v[0]); float β = radian(v[1]); float γ = radian(v[2]);
  Matrix mt = {
    data: [
  cos(α)*cos(β), (cos(α)*sin(β)*sin(γ)) - (sin(α)*cos(γ)), (cos(α)*sin(β)*cos(γ)) + (sin(β)*sin(γ)), 0.0f,
  sin(α)*cos(β), (sin(α)*sin(β)*sin(γ)) + (cos(α)*cos(γ)), (sin(α)*sin(β)*cos(γ)) - (cos(β)*sin(γ)), 0.0f,
  -sin(β)      ,  cos(β)*sin(γ)                          ,  cos(β)*cos(γ)                          , 0.0f,
   0.0f        ,  0.0f                                   ,  0.0f,                                    1.0f ]
  };
  auto r = m.multiply(mt);
  return(r);
}

/* ref Matrix x Yaw, Pitch, Roll vector in degrees V(x, y, z) */
//@nogc pure Matrix rotate(ref Matrix m, const float[3] v) nothrow { m = rotate(m, v); return(m); }

/* Matrix x Scale V(x, y, z) */
@nogc pure Matrix scale(ref Matrix m, const float[3] v) nothrow {
    Matrix scale;
    scale[0] = v[0]; scale[5] = v[1]; scale[10] = v[2];
    m = multiply(m, scale);
    return(m);
}

/* Matrix x Translation V(x, y, z) */
@nogc pure Matrix translate(const Matrix m, const float[3] v) nothrow {
    Matrix translation;
    translation[12] = v[0]; translation[13] = v[1]; translation[14] = v[2];
    return(multiply(m, translation));
}

/* Orthogonal projection Matrix V4(l, r, b, t) */
@nogc pure Matrix orthogonal(float left, float right, float bottom, float top) nothrow {
    Matrix projection;

    projection[0] = 2 / (right - left);
    projection[5] = 2 / (top - bottom);
    projection[10] = -1;
    projection[12] = - (right + left) / (right - left);
    projection[13] = - (top + bottom) / (top - bottom);

    return projection;
}

/* Perspective projection Matrix V4(f, a, n, f) */
@nogc pure Matrix perspective(float fovy, float aspect_ratio, float near, float far) nothrow {
    Matrix projection;

    float y_scale = (1.0f / cos(fovy * PI / 180.0f));
    float x_scale = y_scale / aspect_ratio;
    float frustum_length = far - near;

    projection[0] = x_scale;
    projection[5] = -y_scale;
    projection[10] = -((far + near) / frustum_length);
    projection[11] = -1;
    projection[14] = -((2 * near * far) / frustum_length);

    return projection;
}

/* lookAt function, looks from pos at "at" using the upvector (up) */
@nogc pure Matrix lookAt(const float[3] pos, const float[3] at, const float[3] up) nothrow {
    Matrix view;

    auto f = vSub(at, pos);
    normalize(f);
    auto s = cross(f, up);
    normalize(s);
    auto u = cross(s, f);

    view[0] = s[0];  view[4] = s[1];  view[8]  = s[2];
    view[1] = u[0];  view[5] = u[1];  view[9]  = u[2];
    view[2] = -f[0]; view[6] = -f[1]; view[10] = -f[2];

    view[12] = -dot(s, pos);
    view[13] = -dot(u, pos);
    view[14] =  dot(f, pos);

    return view;
}

/* transpose a Matrix */
@nogc pure Matrix transpose(const Matrix m) nothrow {
  Matrix mt;
  for (size_t row = 0; row < 4; ++row) {
    for (size_t col = 0; col < 4; ++col) {
      mt[(col * 4) + row] = m[(row * 4) + col];
    }
  }
  return(mt);
}

/* inverse of a Matrix using the determinant */
@nogc pure Matrix inverse(const Matrix m) nothrow {
    Matrix inv;

    inv[0] = m[5]  * m[10] * m[15] - m[5]  * m[11] * m[14] - 
             m[9]  * m[6]  * m[15] + m[9]  * m[7]  * m[14] +
             m[13] * m[6]  * m[11] - m[13] * m[7]  * m[10];

    inv[4] = -m[4]  * m[10] * m[15] + m[4]  * m[11] * m[14] + 
              m[8]  * m[6]  * m[15] - m[8]  * m[7]  * m[14] - 
              m[12] * m[6]  * m[11] + m[12] * m[7]  * m[10];

    inv[8] = m[4]  * m[9] * m[15] - m[4]  * m[11] * m[13] - 
             m[8]  * m[5] * m[15] + m[8]  * m[7]  * m[13] + 
             m[12] * m[5] * m[11] - m[12] * m[7]  * m[9];

    inv[12] = -m[4]  * m[9] * m[14] + m[4]  * m[10] * m[13] +
               m[8]  * m[5] * m[14] - m[8]  * m[6]  * m[13] - 
               m[12] * m[5] * m[10] + m[12] * m[6]  * m[9];

    inv[1] = -m[1]  * m[10] * m[15] + m[1]  * m[11] * m[14] + 
              m[9]  * m[2]  * m[15] - m[9]  * m[3] * m[14] - 
              m[13] * m[2]  * m[11] + m[13] * m[3] * m[10];

    inv[5] = m[0]  * m[10] * m[15] - m[0]  * m[11] * m[14] - 
             m[8]  * m[2]  * m[15] + m[8]  * m[3] * m[14] + 
             m[12] * m[2]  * m[11] - m[12] * m[3] * m[10];

    inv[9] = -m[0]  * m[9] * m[15] + m[0]  * m[11] * m[13] + 
              m[8]  * m[1] * m[15] - m[8]  * m[3]  * m[13] - 
              m[12] * m[1] * m[11] + m[12] * m[3]  * m[9];

    inv[13] = m[0]  * m[9] * m[14] - m[0]  * m[10] * m[13] - 
              m[8]  * m[1] * m[14] + m[8]  * m[2]  * m[13] + 
              m[12] * m[1] * m[10] - m[12] * m[2]  * m[9];

    inv[2] = m[1]  * m[6] * m[15] - m[1]  * m[7] * m[14] - 
             m[5]  * m[2] * m[15] + m[5]  * m[3] * m[14] + 
             m[13] * m[2] * m[7]  - m[13] * m[3] * m[6];

    inv[6] = -m[0]  * m[6] * m[15] + m[0]  * m[7] * m[14] + 
              m[4]  * m[2] * m[15] - m[4]  * m[3] * m[14] - 
              m[12] * m[2] * m[7]  + m[12] * m[3] * m[6];

    inv[10] = m[0]  * m[5] * m[15] - m[0]  * m[7] * m[13] - 
              m[4]  * m[1] * m[15] + m[4]  * m[3] * m[13] + 
              m[12] * m[1] * m[7]  - m[12] * m[3] * m[5];

    inv[14] = -m[0]  * m[5] * m[14] + m[0]  * m[6] * m[13] + 
               m[4]  * m[1] * m[14] - m[4]  * m[2] * m[13] - 
               m[12] * m[1] * m[6]  + m[12] * m[2] * m[5];

    inv[3] = -m[1] * m[6] * m[11] + m[1] * m[7] * m[10] + 
              m[5] * m[2] * m[11] - m[5] * m[3] * m[10] - 
              m[9] * m[2] * m[7]  + m[9] * m[3] * m[6];

    inv[7] = m[0] * m[6] * m[11] - m[0] * m[7] * m[10] - 
             m[4] * m[2] * m[11] + m[4] * m[3] * m[10] + 
             m[8] * m[2] * m[7]  - m[8] * m[3] * m[6];

    inv[11] = -m[0] * m[5] * m[11] + m[0] * m[7] * m[9] + 
               m[4] * m[1] * m[11] - m[4] * m[3] * m[9] - 
               m[8] * m[1] * m[7]  + m[8] * m[3] * m[5];

    inv[15] = m[0] * m[5] * m[10] - m[0] * m[6] * m[9] - 
              m[4] * m[1] * m[10] + m[4] * m[2] * m[9] + 
              m[8] * m[1] * m[6]  - m[8] * m[2] * m[5];

    float det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

    if (det == 0) return Matrix();

    det = 1.0f / det;

    inv[] = inv[] * det;

    return inv;
}
