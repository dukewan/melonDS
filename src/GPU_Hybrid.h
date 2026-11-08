/*
    Copyright 2016-2025 melonDS team

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

#ifndef GPU_HYBRID_H
#define GPU_HYBRID_H

#ifdef OGLRENDERER_ENABLED

#include "GPU.h"
#include "GPU_Soft.h"
#include "GPU3D_OpenGL.h"

namespace melonDS
{

/// 游典's hybrid renderer: the 3D drawn by the GPU (GLRenderer3D, at a raised size), the 2D by the
/// software renderer (SoftRenderer2D, melonDS's own: the OpenGL 2D renderer garbles some games'
/// 2D), the two put together on the GPU by a compositor — the way melonDS 1.1's OpenGL renderer
/// worked (its GLCompositor), brought back on the newer renderer interface. The software 2D keeps
/// the layers round a 3D pixel apart (Soft2DHost::Accelerated, 1.1's val1/val2/val3 layout) and
/// the compositor shader (OpenGL_shaders/HybridCompositorFS.glsl) puts the GPU's 3D in and blends.
/// Display capture of the 3D takes it at the DS's own size, read back from the GPU for the frame
/// (GLRenderer3D::PrepareCaptureFrame). The output is a two-layer array texture, as GLRenderer's.
class HybridRenderer : public Renderer, public Soft2DHost, public GL3DHost
{
public:
    explicit HybridRenderer(melonDS::NDS& nds);
    ~HybridRenderer() override;
    bool Init() override;
    void Reset() override;
    void Stop() override;

    void PostSavestate() override;

    void SetRenderSettings(RendererSettings& settings) override;

    void DrawScanline(u32 line) override;
    void DrawSprites(u32 line) override;

    void VBlank() override;
    void VBlankEnd() override {}

    // Captures go straight to VRAM, as the software renderer's.
    void AllocCapture(u32 bank, u32 start, u32 len) override {}
    void SyncVRAMCapture(u32 bank, u32 start, u32 len, bool complete) override {}

    bool GetFramebuffers(void** top, void** bottom) override;

    [[nodiscard]] int GetScaleFactor() const noexcept { return ScaleFactor; }

private:
    /// A line of the software composite: val1, val2, val3, then the line's display mode, master
    /// brightness and 3D x offset for the compositor (1.1's layout).
    static constexpr int Stride = 256*3 + 1;

    u32* Framebuffer[2][2] {};

    alignas(8) u32 BlankLine[256] {};
    alignas(8) u32 CaptureLine[256] {};
    bool Capturing3D = false;

    int ScaleFactor = 0;
    int ScreenW = 0, ScreenH = 0;

    GLuint CompShader = 0;
    GLint CompScaleLoc = -1;
    GLuint VertexBuffer = 0, VertexArray = 0;
    GLuint InputTex = 0;
    GLuint OutputTex[2] {};
    GLuint OutputFB[2][2] {};

    void SetScaleFactor(int scale);
    void ClearFramebuffers();
    void DrawScanlineA(u32 line, u32* dst);
    void DrawScanlineB(u32 line, u32* dst);
    void DoCapture(u32 line);
    void Composite();
};

}

#endif

#endif // GPU_HYBRID_H
