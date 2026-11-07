/*
    Copyright 2016-2026 melonDS team

    This file is part of melonDS.

    melonDS is free software: you can redistribute it and/or modify it under
    the terms of the GNU General Public License as published by the Free
    Software Foundation, either version 3 of the License, or (at your option)
    any later version.

    melonDS is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with melonDS. If not, see http://www.gnu.org/licenses/.
*/

#ifndef OPENGLSUPPORT_H
#define OPENGLSUPPORT_H

#include <stdio.h>
#include <string.h>

#include "Platform.h"
#include "PlatformOGL.h"

namespace melonDS::OpenGL
{

void LoadShaderCache();
void SaveShaderCache();

struct AttributeTarget
{
    const char* Name;
    u32 Location;
};


bool CompileVertexFragmentProgram(GLuint& result,
    const std::string& vs, const std::string& fs,
    const std::string& name,
    const std::initializer_list<AttributeTarget>& vertexInAttrs,
    const std::initializer_list<AttributeTarget>& fragmentOutAttrs);

bool CompileComputeProgram(GLuint& result, const std::string& source, const std::string& name);

// The DS's 15-bit colours (bit 15 alpha, then blue, green, red from the top): desktop OpenGL takes
// them as GL_UNSIGNED_SHORT_1_5_5_5_REV; OpenGL ES (游典, Android) has no such type, so they're
// uploaded as GL_UNSIGNED_SHORT_5_5_5_1, reordered first, and read back as bytes.
#ifdef HAVE_OPENGLES
#define MELONDS_GL_TYPE_1555 GL_UNSIGNED_SHORT_5_5_5_1
#else
#define MELONDS_GL_TYPE_1555 GL_UNSIGNED_SHORT_1_5_5_5_REV
#endif
// [count] DS colours ready for MELONDS_GL_TYPE_1555 (a buffer of this thread's, until the next call).
const void* Pixels1555(const void* colors, size_t count);
// glReadPixels of a w x h RGBA area as DS colours.
void ReadPixels1555(GLint x, GLint y, GLsizei w, GLsizei h, void* out);

}

#endif // OPENGLSUPPORT_H
