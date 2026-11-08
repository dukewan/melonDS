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

#include "GPU_Hybrid.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "NDS.h"
#include "GPU_ColorOp.h"
#include "OpenGLSupport.h"
#include "OpenGL_shaders/HybridCompositorVS.h"
#include "OpenGL_shaders/HybridCompositorFS.h"

namespace melonDS
{

HybridRenderer::HybridRenderer(melonDS::NDS& nds)
    : Renderer(nds.GPU)
{
    const size_t len = Stride * 192;
    Framebuffer[0][0] = new u32[len];
    Framebuffer[0][1] = new u32[len];
    Framebuffer[1][0] = new u32[len];
    Framebuffer[1][1] = new u32[len];
    BackBuffer = 0;

    // The 2D composite keeps the layers round a 3D pixel apart for the compositor.
    Accelerated = true;
    Output3D = BlankLine;

    Rend2D_A = std::make_unique<SoftRenderer2D>(GPU.GPU2D_A, *this);
    Rend2D_B = std::make_unique<SoftRenderer2D>(GPU.GPU2D_B, *this);
    Rend3D = std::make_unique<GLRenderer3D>(GPU.GPU3D, *this);
}

HybridRenderer::~HybridRenderer()
{
    assert(glDeleteTextures != nullptr);

    glDeleteFramebuffers(4, &OutputFB[0][0]);
    glDeleteTextures(2, OutputTex);
    glDeleteTextures(1, &InputTex);
    glDeleteVertexArrays(1, &VertexArray);
    glDeleteBuffers(1, &VertexBuffer);
    glDeleteProgram(CompShader);

    delete[] Framebuffer[0][0];
    delete[] Framebuffer[0][1];
    delete[] Framebuffer[1][0];
    delete[] Framebuffer[1][1];
}

bool HybridRenderer::Init()
{
    if (!Rend2D_A->Init() || !Rend2D_B->Init() || !Rend3D->Init())
        return false;

    if (!OpenGL::CompileVertexFragmentProgram(CompShader,
            kHybridCompositorVS, kHybridCompositorFS,
            "HybridCompositorShader",
            {{"vPosition", 0}, {"vTexcoord", 1}},
            {{"oColor", 0}}))
        return false;

    CompScaleLoc = glGetUniformLocation(CompShader, "u3DScale");
    glUseProgram(CompShader);
    glUniform1i(glGetUniformLocation(CompShader, "ScreenTex"), 0);
    glUniform1i(glGetUniformLocation(CompShader, "_3DTex"), 1);

    // Two quads, one a screen: clip space, and the software composite's pixels (row 0 of the
    // output is the screen's first line, as the GLRenderer's output and the 3D are laid).
    struct Vertex { float x, y, u, v; };
    Vertex vertices[12];
    for (int screen = 0; screen < 2; screen++)
    {
        float v0 = 192.f * screen, v1 = v0 + 192.f;
        Vertex* q = &vertices[screen * 6];
        q[0] = {-1, -1, 0, v0};
        q[1] = { 1, -1, 256, v0};
        q[2] = { 1,  1, 256, v1};
        q[3] = {-1, -1, 0, v0};
        q[4] = { 1,  1, 256, v1};
        q[5] = {-1,  1, 0, v1};
    }
    glGenBuffers(1, &VertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, VertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glGenVertexArrays(1, &VertexArray);
    glBindVertexArray(VertexArray);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(2 * sizeof(float)));

    // The software composite of both screens, as the shader reads it: integers, three slots and
    // the line's column.
    glGenTextures(1, &InputTex);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, InputTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8UI, Stride, 192*2, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, nullptr);

    glGenTextures(2, OutputTex);
    for (int i = 0; i < 2; i++)
    {
        glBindTexture(GL_TEXTURE_2D_ARRAY, OutputTex[i]);
        glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
    glGenFramebuffers(4, &OutputFB[0][0]);

    glBindVertexArray(0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return true;
}

void HybridRenderer::ClearFramebuffers()
{
    const size_t len = Stride * 192 * sizeof(u32);
    memset(Framebuffer[0][0], 0, len);
    memset(Framebuffer[0][1], 0, len);
    memset(Framebuffer[1][0], 0, len);
    memset(Framebuffer[1][1], 0, len);
}

void HybridRenderer::Reset()
{
    ClearFramebuffers();
    Capturing3D = false;
    Rend2D_A->Reset();
    Rend2D_B->Reset();
    Rend3D->Reset();
}

void HybridRenderer::Stop()
{
    ClearFramebuffers();
}

void HybridRenderer::PostSavestate()
{
    // The 3D's texture cache is of the state before.
    Rend3D->Reset();
}

void HybridRenderer::SetRenderSettings(RendererSettings& settings)
{
    SetScaleFactor(settings.ScaleFactor);
    auto rend3d = dynamic_cast<GLRenderer3D*>(Rend3D.get());
    rend3d->SetRenderSettings(settings.ScaleFactor, settings.BetterPolygons);
}

void HybridRenderer::SetScaleFactor(int scale)
{
    if (scale == ScaleFactor)
        return;

    ScaleFactor = scale;
    ScreenW = 256 * scale;
    ScreenH = 192 * scale;

    for (int i = 0; i < 2; i++)
    {
        glBindTexture(GL_TEXTURE_2D_ARRAY, OutputTex[i]);
        glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA, ScreenW, ScreenH, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
        for (int layer = 0; layer < 2; layer++)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, OutputFB[i][layer]);
            glFramebufferTextureLayer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, OutputTex[i], 0, layer);
            const GLenum draw = GL_COLOR_ATTACHMENT0;
            glDrawBuffers(1, &draw);
        }
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void HybridRenderer::DrawScanline(u32 line)
{
    u32 *dstA, *dstB;
    u32 dstoffset = Stride * line;
    if (GPU.ScreenSwap)
    {
        dstA = &Framebuffer[BackBuffer][0][dstoffset];
        dstB = &Framebuffer[BackBuffer][1][dstoffset];
    }
    else
    {
        dstA = &Framebuffer[BackBuffer][1][dstoffset];
        dstB = &Framebuffer[BackBuffer][0][dstoffset];
    }

    // the position used for drawing operations is based on VCOUNT
    line = GPU.VCount;
    if (line < 192)
    {
        // The 3D at the DS's own size is wanted only by a capture of it (the screen gets the
        // GPU's, put in by the compositor): read back from the GPU for the frame, at its first line.
        if (line == 0)
        {
            Capturing3D = GPU.CaptureEnable && (((GPU.CaptureCnt >> 29) & 0x3) != 1);
            if (Capturing3D)
                dynamic_cast<GLRenderer3D*>(Rend3D.get())->PrepareCaptureFrame();
        }
        Output3D = Capturing3D ? Rend3D->GetLine(line) : BlankLine;

        // draw BG/OBJ layers
        Rend2D_A->DrawScanline(line);
        Rend2D_B->DrawScanline(line);

        // the final screen output, the 3D left to the compositor
        DrawScanlineA(line, dstA);
        DrawScanlineB(line, dstB);

        // perform display capture if enabled
        if (GPU.CaptureEnable)
            DoCapture(line);
    }
    else
    {
        // scanlines outside VCOUNT range 0..191: white, as the software renderer's
        for (int i = 0; i < 256; i++)
        {
            dstA[i] = 0x3F3F3F;
            dstB[i] = 0x3F3F3F;
        }
        dstA[256*3] = 0;
        dstB[256*3] = 0;
    }

    if (!GPU.ScreensEnabled)
    {
        // if the screens are disabled: black (display mode 0 in the column: nothing done to it)
        memset(dstA, 0, 256 * sizeof(u32));
        memset(dstB, 0, 256 * sizeof(u32));
        dstA[256*3] = 0;
        dstB[256*3] = 0;
    }
}

void HybridRenderer::DrawSprites(u32 line)
{
    Rend2D_A->DrawSprites(line);
    Rend2D_B->DrawSprites(line);
}

void HybridRenderer::DrawScanlineA(u32 line, u32* dst)
{
    u32 dispcnt = GPU.GPU2D_A.DispCnt;
    u32 dispmode = (dispcnt >> 16) & 0x3;
    switch (dispmode)
    {
    case 0: // screen off
        {
            for (int i = 0; i < 256; i++)
                dst[i] = 0x3F3F3F;
        }
        break;

    case 1: // regular display: the three slots
        {
            for (int i = 0; i < 256*3; i+=2)
                *(u64*)&dst[i] = *(u64*)&Output2D[0][i];
        }
        break;

    case 2: // VRAM display
        {
            u32 vrambank = (dispcnt >> 18) & 0x3;
            if (GPU.VRAMMap_LCDC & (1<<vrambank))
            {
                u16* vram = (u16*)GPU.VRAM[vrambank];
                vram = &vram[line * 256];

                for (int i = 0; i < 256; i++)
                {
                    u16 color = vram[i];
                    u8 r = (color & 0x001F) << 1;
                    u8 g = (color & 0x03E0) >> 4;
                    u8 b = (color & 0x7C00) >> 9;

                    dst[i] = r | (g << 8) | (b << 16);
                }
            }
            else
            {
                for (int i = 0; i < 256; i++)
                    dst[i] = 0;
            }
        }
        break;

    case 3: // FIFO display
        {
            for (int i = 0; i < 256; i++)
            {
                u16 color = GPU.DispFIFOBuffer[i];
                u8 r = (color & 0x001F) << 1;
                u8 g = (color & 0x03E0) >> 4;
                u8 b = (color & 0x7C00) >> 9;

                dst[i] = r | (g << 8) | (b << 16);
            }
        }
        break;
    }

    // The line's column for the compositor: master brightness, display mode, the 3D's x offset.
    u32 xpos = GPU.GPU3D.GetRenderXPos();
    dst[256*3] = GPU.MasterBrightnessA | (dispcnt & 0x30000) | (xpos << 24) | ((xpos & 0x100) << 15);
}

void HybridRenderer::DrawScanlineB(u32 line, u32* dst)
{
    u32 dispcnt = GPU.GPU2D_B.DispCnt;
    u32 dispmode = (dispcnt >> 16) & 0x1;
    switch (dispmode)
    {
    case 0: // screen off
        {
            for (int i = 0; i < 256; i++)
                dst[i] = 0x3F3F3F;
        }
        break;

    case 1: // regular display
        {
            for (int i = 0; i < 256*3; i+=2)
                *(u64*)&dst[i] = *(u64*)&Output2D[1][i];
        }
        break;
    }

    dst[256*3] = GPU.MasterBrightnessB | (dispcnt & 0x10000);
}

void HybridRenderer::DoCapture(u32 line)
{
    u32 captureCnt = GPU.CaptureCnt;
    u32* src2D = Output2D[0];

    if (!(captureCnt & (1<<24)))
    {
        // The 2D with the 3D in it as source A: composited here, the compositor's way (with the 3D
        // at the DS's size), as melonDS 1.1's accelerated capture did.
        for (int i = 0; i < 256; i++)
        {
            u32 val1 = Output2D[0][i];
            u32 val2 = Output2D[0][256+i];
            u32 val3 = Output2D[0][512+i];

            u32 compmode = (val3 >> 24) & 0xF;

            if (compmode == 4)
            {
                // 3D on top, blending
                u32 _3dval = Output3D[i];
                if ((_3dval >> 24) > 0)
                    val1 = ColorBlend5(_3dval, val1);
                else
                    val1 = val2;
            }
            else if (compmode == 1)
            {
                // 3D on bottom, blending
                u32 _3dval = Output3D[i];
                if ((_3dval >> 24) > 0)
                {
                    u32 eva = (val3 >> 8) & 0x1F;
                    u32 evb = (val3 >> 16) & 0x1F;
                    val1 = ColorBlend4(val1, _3dval, eva, evb);
                }
                else
                    val1 = val2;
            }
            else if (compmode <= 3)
            {
                // 3D on top, normal/fade
                u32 _3dval = Output3D[i];
                if ((_3dval >> 24) > 0)
                {
                    u32 evy = (val3 >> 8) & 0x1F;
                    val1 = _3dval;
                    if      (compmode == 2) val1 = ColorBrightnessUp(val1, evy, 0x8);
                    else if (compmode == 3) val1 = ColorBrightnessDown(val1, evy, 0x7);
                }
                else
                    val1 = val2;
            }

            CaptureLine[i] = val1;
        }
        src2D = CaptureLine;
    }

    SoftRenderer::CaptureScanline(GPU, line, src2D, Output3D);
}

void HybridRenderer::VBlank()
{
    Rend2D_A->VBlank();
    Rend2D_B->VBlank();
    Composite();
}

/// The frame just drawn (both screens' software composite and the GPU's 3D) into the output's
/// back buffer.
void HybridRenderer::Composite()
{
    if (!ScaleFactor)
        return;

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_SCISSOR_TEST);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    glUseProgram(CompShader);
    glUniform1ui(CompScaleLoc, ScaleFactor);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, InputTex);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, Stride, 192, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, Framebuffer[BackBuffer][0]);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 192, Stride, 192, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, Framebuffer[BackBuffer][1]);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, OutputTex3D);

    glBindVertexArray(VertexArray);
    glViewport(0, 0, ScreenW, ScreenH);
    for (int screen = 0; screen < 2; screen++)
    {
        glBindFramebuffer(GL_FRAMEBUFFER, OutputFB[BackBuffer][screen]);
        glDrawArrays(GL_TRIANGLES, screen * 6, 6);
    }

    glBindVertexArray(0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glActiveTexture(GL_TEXTURE0);
}

bool HybridRenderer::GetFramebuffers(void** top, void** bottom)
{
    // an array texture: one layer a screen, so only the first pointer is needed (as GLRenderer's)
    int frontbuf = BackBuffer ^ 1;
    *top = &OutputTex[frontbuf];
    *bottom = nullptr;
    return false;
}

}
