#version 140

// 游典's hybrid renderer (GPU_Hybrid.cpp): the software 2D renderer's composite of a line, with the
// layers round a 3D pixel kept apart (val1, val2, val3 — melonDS 1.1's accelerated layout), and the
// 3D drawn by the GPU at a raised size put in where it goes, the DS's blending done here.

uniform uint u3DScale;
uniform usampler2D ScreenTex;
uniform sampler2D _3DTex;

smooth in vec2 fTexcoord;

out vec4 oColor;

void main()
{
    ivec4 pixel = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord), 0));

    ivec4 mbright = ivec4(texelFetch(ScreenTex, ivec2(256*3, int(fTexcoord.y)), 0));
    int dispmode = mbright.b & 0x3;

    // mbright.a == HOFS bit0..7
    // mbright.b bit7 == HOFS bit8 (sign)
    float _3dxpos = float(mbright.a - ((mbright.b & 0x80) * 2));

    if (dispmode == 1)
    {
        ivec4 val1 = pixel;
        ivec4 val2 = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord) + ivec2(256,0), 0));
        ivec4 val3 = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord) + ivec2(512,0), 0));

        int compmode = val3.a & 0xF;
        int eva, evb, evy;

        if (compmode <= 4)
        {
            // a 3D pixel may be here: the GPU's, 6-bit colour and 5-bit alpha as the 2D's
            float xpos = fTexcoord.x + _3dxpos;
            float ypos = mod(fTexcoord.y, 192.0);
            ivec4 _3dpix = ivec4(0);
            if (xpos >= 0.0 && xpos < 256.0)
                _3dpix = ivec4(texelFetch(_3DTex, ivec2(vec2(xpos, ypos) * float(u3DScale)), 0) * 255.0) >> ivec4(2,2,2,3);

            if (compmode == 4)
            {
                // 3D on top, blending
                if (_3dpix.a > 0)
                {
                    eva = (_3dpix.a & 0x1F) + 1;
                    evb = 32 - eva;
                    val1 = ((_3dpix * eva) + (val1 * evb) + 0x10) >> 5;
                    val1 = min(val1, 0x3F);
                }
                else
                    val1 = val2;
            }
            else if (compmode == 1)
            {
                // 3D on bottom, blending
                if (_3dpix.a > 0)
                {
                    eva = val3.g;
                    evb = val3.b;
                    val1 = ((val1 * eva) + (_3dpix * evb) + 0x8) >> 4;
                    val1 = min(val1, 0x3F);
                }
                else
                    val1 = val2;
            }
            else
            {
                // 3D on top, normal/fade
                if (_3dpix.a > 0)
                {
                    evy = val3.g;
                    val1 = _3dpix;
                    if      (compmode == 2) val1 += (((0x3F - val1) * evy) + 0x8) >> 4;
                    else if (compmode == 3) val1 -= ((val1 * evy) + 0x7) >> 4;
                }
                else
                    val1 = val2;
            }
        }

        pixel = val1;
    }

    if (dispmode != 0)
    {
        int brightmode = mbright.g >> 6;
        if (brightmode == 1)
        {
            // up
            int evy = mbright.r & 0x1F;
            if (evy > 16) evy = 16;
            pixel += ((0x3F - pixel) * evy) >> 4;
        }
        else if (brightmode == 2)
        {
            // down
            int evy = mbright.r & 0x1F;
            if (evy > 16) evy = 16;
            pixel -= ((pixel * evy) + 0xF) >> 4;
        }
    }

    pixel.rgb <<= 2;
    pixel.rgb |= (pixel.rgb >> 6);

    oColor = vec4(vec3(pixel.rgb) / 255.0, 1.0);
}
