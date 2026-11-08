#version 320 es
precision highp float;
precision highp int;

uniform highp usampler2D ScreenTex;
uniform highp sampler2D _3DTex;
uniform uint u3DScale;

in highp vec2 fTexcoord;
out highp vec4 oColor;

void main()
{
    ivec4 pixel = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord), 0));
    ivec4 mbright = ivec4(texelFetch(ScreenTex, ivec2(768, int(fTexcoord.y)), 0));
    int dispmode = mbright.z & 3;
    highp float _3dxpos = float(mbright.w - ((mbright.z & 128) * 2));
    if (dispmode == 1)
    {
        ivec4 val1 = pixel;
        ivec4 val2 = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord) + ivec2(256, 0), 0));
        ivec4 val3 = ivec4(texelFetch(ScreenTex, ivec2(fTexcoord) + ivec2(512, 0), 0));
        int compmode = val3.w & 15;
        if (compmode <= 4)
        {
            highp float xpos = fTexcoord.x + _3dxpos;
            highp float ypos = mod(fTexcoord.y, 192.0);
            ivec4 _3dpix = ivec4(0);
            if ((xpos >= 0.0) && (xpos < 256.0))
            {
                _3dpix = ivec4(texelFetch(_3DTex, ivec2(vec2(xpos, ypos) * float(u3DScale)), 0) * 255.0) >> ivec4(2, 2, 2, 3);
            }
            int eva;
            int evb;
            if (compmode == 4)
            {
                if (_3dpix.w > 0)
                {
                    eva = (_3dpix.w & 31) + 1;
                    evb = 32 - eva;
                    val1 = (((_3dpix * ivec4(eva)) + (val1 * ivec4(evb))) + ivec4(16)) >> ivec4(5);
                    val1 = min(val1, ivec4(63));
                }
                else
                {
                    val1 = val2;
                }
            }
            else
            {
                if (compmode == 1)
                {
                    if (_3dpix.w > 0)
                    {
                        eva = val3.y;
                        evb = val3.z;
                        val1 = (((val1 * ivec4(eva)) + (_3dpix * ivec4(evb))) + ivec4(8)) >> ivec4(4);
                        val1 = min(val1, ivec4(63));
                    }
                    else
                    {
                        val1 = val2;
                    }
                }
                else
                {
                    if (_3dpix.w > 0)
                    {
                        int evy = val3.y;
                        val1 = _3dpix;
                        if (compmode == 2)
                        {
                            val1 += ((((ivec4(63) - val1) * ivec4(evy)) + ivec4(8)) >> ivec4(4));
                        }
                        else
                        {
                            if (compmode == 3)
                            {
                                val1 -= (((val1 * ivec4(evy)) + ivec4(7)) >> ivec4(4));
                            }
                        }
                    }
                    else
                    {
                        val1 = val2;
                    }
                }
            }
        }
        pixel = val1;
    }
    if (dispmode != 0)
    {
        int brightmode = mbright.y >> 6;
        if (brightmode == 1)
        {
            int evy_1 = mbright.x & 31;
            if (evy_1 > 16)
            {
                evy_1 = 16;
            }
            pixel += (((ivec4(63) - pixel) * ivec4(evy_1)) >> ivec4(4));
        }
        else
        {
            if (brightmode == 2)
            {
                int evy_2 = mbright.x & 31;
                if (evy_2 > 16)
                {
                    evy_2 = 16;
                }
                pixel -= (((pixel * ivec4(evy_2)) + ivec4(15)) >> ivec4(4));
            }
        }
    }
    ivec4 _315 = pixel;
    ivec3 _318 = _315.xyz << ivec3(2);
    pixel.x = _318.x;
    pixel.y = _318.y;
    pixel.z = _318.z;
    ivec4 _325 = pixel;
    ivec4 _329 = pixel;
    ivec3 _331 = _329.xyz | (_325.xyz >> ivec3(6));
    pixel.x = _331.x;
    pixel.y = _331.y;
    pixel.z = _331.z;
    oColor = vec4(vec3(pixel.xyz) / vec3(255.0), 1.0);
}

