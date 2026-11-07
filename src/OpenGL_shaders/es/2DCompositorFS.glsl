#version 320 es
precision highp float;
precision highp int;

struct sScanline
{
    ivec2 BGOffset[4];
    ivec4 BGRotscale[2];
    int BackColor;
    uint WinRegs;
    int WinMask;
    ivec4 WinPos;
    uvec4 BGMosaicEnable;
    ivec4 MosaicSize;
};

struct sBGConfig
{
    ivec2 Size;
    int Type;
    int PalOffset;
    int TileOffset;
    int MapOffset;
    uint Clamp;
};

layout(std140) uniform ubScanlineConfig
{
    sScanline uScanline[192];
} _137;

layout(std140) uniform ubBGConfig
{
    int uVRAMMask;
    sBGConfig uBGConfig[4];
} _169;

layout(std140) uniform ubCompositorConfig
{
    ivec4 uBGPrio;
    uint uEnableOBJ;
    uint uEnable3D;
    int uBlendCnt;
    int uBlendEffect;
    ivec3 uBlendCoef;
} _797;

uniform highp sampler2D BGLayerTex[4];
uniform highp sampler2DArray Capture128Tex;
uniform highp sampler2DArray Capture256Tex;
uniform highp isampler2D MosaicTex;
uniform highp sampler2DArray OBJLayerTex;
uniform int uScaleFactor;

in highp vec4 fTexcoord;
out highp vec4 oColor;
int MosaicX;

ivec3 ConvertColor(int col)
{
    ivec3 ret;
    ret.x = (col & 31) << 1;
    ret.y = ((col & 992) >> 4) | (col >> 15);
    ret.z = (col & 31744) >> 9;
    return ret;
}

highp vec4 BG0Fetch(highp vec2 coord)
{
    return texture(BGLayerTex[0], coord);
}

highp vec4 BG0CalcAndFetch(highp vec2 coord, int line)
{
    ivec2 bgoffset = _137.uScanline[line].BGOffset[0];
    highp vec2 bgpos = vec2(bgoffset) + coord;
    if (_137.uScanline[line].BGMosaicEnable.x != 0u)
    {
        bgpos = floor(bgpos) - vec2(float(MosaicX), 0.0);
    }
    highp vec2 param = bgpos / vec2(_169.uBGConfig[0].Size);
    return BG0Fetch(param);
}

highp vec4 BG1Fetch(highp vec2 coord)
{
    return texture(BGLayerTex[1], coord);
}

highp vec4 BG1CalcAndFetch(highp vec2 coord, int line)
{
    ivec2 bgoffset = _137.uScanline[line].BGOffset[1];
    highp vec2 bgpos = vec2(bgoffset) + coord;
    if (_137.uScanline[line].BGMosaicEnable.y != 0u)
    {
        bgpos = floor(bgpos) - vec2(float(MosaicX), 0.0);
    }
    highp vec2 param = bgpos / vec2(_169.uBGConfig[1].Size);
    return BG1Fetch(param);
}

highp vec4 BG2Fetch(highp vec2 coord)
{
    return texture(BGLayerTex[2], coord);
}

highp vec4 BG2CalcAndFetch(highp vec2 coord, int line)
{
    ivec2 bgoffset = _137.uScanline[line].BGOffset[2];
    highp vec2 bgpos;
    if (_169.uBGConfig[2].Type >= 2)
    {
        bgpos = vec2(bgoffset) / vec2(256.0);
        highp vec4 rotscale = vec4(_137.uScanline[line].BGRotscale[0]) / vec4(256.0);
        highp mat2 rsmatrix = mat2(vec2(rotscale.xy), vec2(rotscale.zw));
        bgpos += (coord * rsmatrix);
    }
    else
    {
        bgpos = vec2(bgoffset) + coord;
    }
    if (_137.uScanline[line].BGMosaicEnable.z != 0u)
    {
        bgpos = floor(bgpos) - vec2(float(MosaicX), 0.0);
    }
    if (_169.uBGConfig[2].Type >= 7)
    {
        bgpos.y += float(_169.uBGConfig[2].MapOffset);
        highp vec3 capcoord = vec3(bgpos / vec2(_169.uBGConfig[2].Size), float(_169.uBGConfig[2].TileOffset));
        if (_169.uBGConfig[2].Clamp != 0u)
        {
            bool _308 = any(lessThan(capcoord.xy, vec2(0.0)));
            bool _317;
            if (!_308)
            {
                _317 = any(greaterThanEqual(capcoord.xy, vec2(1.0)));
            }
            else
            {
                _317 = _308;
            }
            if (_317)
            {
                return vec4(0.0);
            }
        }
        if (_169.uBGConfig[2].Type == 7)
        {
            return texture(Capture128Tex, capcoord);
        }
        else
        {
            return texture(Capture256Tex, capcoord);
        }
    }
    highp vec2 param = bgpos / vec2(_169.uBGConfig[2].Size);
    return BG2Fetch(param);
}

highp vec4 BG3Fetch(highp vec2 coord)
{
    return texture(BGLayerTex[3], coord);
}

highp vec4 BG3CalcAndFetch(highp vec2 coord, int line)
{
    ivec2 bgoffset = _137.uScanline[line].BGOffset[3];
    highp vec2 bgpos;
    if (_169.uBGConfig[3].Type >= 2)
    {
        bgpos = vec2(bgoffset) / vec2(256.0);
        highp vec4 rotscale = vec4(_137.uScanline[line].BGRotscale[1]) / vec4(256.0);
        highp mat2 rsmatrix = mat2(vec2(rotscale.xy), vec2(rotscale.zw));
        bgpos += (coord * rsmatrix);
    }
    else
    {
        bgpos = vec2(bgoffset) + coord;
    }
    if (_137.uScanline[line].BGMosaicEnable.w != 0u)
    {
        bgpos = floor(bgpos) - vec2(float(MosaicX), 0.0);
    }
    if (_169.uBGConfig[3].Type >= 7)
    {
        bgpos.y += float(_169.uBGConfig[3].MapOffset);
        highp vec3 capcoord = vec3(bgpos / vec2(_169.uBGConfig[3].Size), float(_169.uBGConfig[3].TileOffset));
        if (_169.uBGConfig[3].Clamp != 0u)
        {
            bool _438 = any(lessThan(capcoord.xy, vec2(0.0)));
            bool _446;
            if (!_438)
            {
                _446 = any(greaterThanEqual(capcoord.xy, vec2(1.0)));
            }
            else
            {
                _446 = _438;
            }
            if (_446)
            {
                return vec4(0.0);
            }
        }
        if (_169.uBGConfig[3].Type == 7)
        {
            return texture(Capture128Tex, capcoord);
        }
        else
        {
            return texture(Capture256Tex, capcoord);
        }
    }
    highp vec2 param = bgpos / vec2(_169.uBGConfig[3].Size);
    return BG3Fetch(param);
}

void CalcSpriteMosaic(ivec2 coord, inout ivec4 objflags, inout highp vec4 objcolor)
{
    for (int i = 0; i < 16; i++)
    {
        ivec2 curpos = ivec2((coord.x - 15) + i, coord.y);
        if (curpos.x < 0)
        {
            objflags = ivec4(0);
            objcolor = vec4(0.0);
        }
        else
        {
            int mosx = texelFetch(MosaicTex, ivec2(curpos.x, _137.uScanline[curpos.y].MosaicSize.z), 0).x;
            highp vec4 color = texelFetch(OBJLayerTex, ivec3(curpos * ivec2(uScaleFactor), 0), 0);
            ivec4 flags = ivec4(texelFetch(OBJLayerTex, ivec3(curpos * ivec2(uScaleFactor), 1), 0) * 255.0);
            bool latch = false;
            if (mosx == 0)
            {
                latch = true;
            }
            else
            {
                if (flags.y == 0)
                {
                    latch = true;
                }
                else
                {
                    if (objflags.y == 0)
                    {
                        latch = true;
                    }
                    else
                    {
                        if (flags.w < objflags.w)
                        {
                            latch = true;
                        }
                    }
                }
            }
            if (latch)
            {
                objflags = flags;
                objcolor = color;
            }
        }
    }
}

highp vec4 CompositeLayers()
{
    ivec2 coord = ivec2(fTexcoord.zw);
    highp vec2 bgcoord = vec2(fTexcoord.x, fract(fTexcoord.y));
    int xpos = int(fTexcoord.x);
    int line = int(fTexcoord.y);
    if (_137.uScanline[line].MosaicSize.x > 0)
    {
        MosaicX = texelFetch(MosaicTex, ivec2(int(bgcoord.x), _137.uScanline[line].MosaicSize.x), 0).x;
    }
    int param = _137.uScanline[line].BackColor;
    ivec4 col1 = ivec4(ConvertColor(param), 32);
    int mask1 = 32;
    ivec4 col2 = ivec4(0);
    int mask2 = 0;
    bool specialcase = false;
    highp vec2 param_1 = bgcoord;
    int param_2 = line;
    highp vec4 layercol[6];
    layercol[0] = BG0CalcAndFetch(param_1, param_2);
    highp vec2 param_3 = bgcoord;
    int param_4 = line;
    layercol[1] = BG1CalcAndFetch(param_3, param_4);
    highp vec2 param_5 = bgcoord;
    int param_6 = line;
    layercol[2] = BG2CalcAndFetch(param_5, param_6);
    highp vec2 param_7 = bgcoord;
    int param_8 = line;
    layercol[3] = BG3CalcAndFetch(param_7, param_8);
    ivec4 objflags;
    if (_137.uScanline[line].MosaicSize.z > 0)
    {
        ivec2 param_9 = ivec2(fTexcoord.xy);
        ivec4 param_10;
        highp vec4 param_11;
        CalcSpriteMosaic(param_9, param_10, param_11);
        objflags = param_10;
        layercol[4] = param_11;
    }
    else
    {
        layercol[4] = texelFetch(OBJLayerTex, ivec3(coord, 0), 0);
        layercol[5] = texelFetch(OBJLayerTex, ivec3(coord, 1), 0);
        objflags = ivec4(layercol[5] * 255.0);
    }
    int winmask = _137.uScanline[line].WinMask;
    bool inside_win0;
    if (xpos < _137.uScanline[line].WinPos.x)
    {
        inside_win0 = (winmask & 1) != 0;
    }
    else
    {
        if (xpos < _137.uScanline[line].WinPos.y)
        {
            inside_win0 = (winmask & 2) != 0;
        }
        else
        {
            inside_win0 = (winmask & 4) != 0;
        }
    }
    bool inside_win1;
    if (xpos < _137.uScanline[line].WinPos.z)
    {
        inside_win1 = (winmask & 8) != 0;
    }
    else
    {
        if (xpos < _137.uScanline[line].WinPos.w)
        {
            inside_win1 = (winmask & 16) != 0;
        }
        else
        {
            inside_win1 = (winmask & 32) != 0;
        }
    }
    uint winregs = _137.uScanline[line].WinRegs;
    uint winsel = winregs;
    if (objflags.z > 0)
    {
        winsel = winregs >> uint(8);
    }
    if (inside_win1)
    {
        winsel = winregs >> uint(16);
    }
    if (inside_win0)
    {
        winsel = winregs >> uint(24);
    }
    for (int prio = 3; prio >= 0; prio--)
    {
        for (int bg = 3; bg >= 0; bg--)
        {
            bool _802 = _797.uBGPrio[bg] == prio;
            bool _809;
            if (_802)
            {
                _809 = layercol[bg].w > 0.0;
            }
            else
            {
                _809 = _802;
            }
            bool _817;
            if (_809)
            {
                _817 = (winsel & (1u << uint(bg))) != 0u;
            }
            else
            {
                _817 = _809;
            }
            if (_817)
            {
                col2 = col1;
                mask2 = mask1 << 8;
                col1 = ivec4(layercol[bg] * 255.0) >> ivec4(2, 2, 2, 3);
                mask1 = 1 << bg;
                specialcase = (bg == 0) && (_797.uEnable3D != 0u);
            }
        }
        bool _842 = _797.uEnableOBJ != 0u;
        bool _849;
        if (_842)
        {
            _849 = objflags.w == prio;
        }
        else
        {
            _849 = _842;
        }
        bool _855;
        if (_849)
        {
            _855 = layercol[4].w > 0.0;
        }
        else
        {
            _855 = _849;
        }
        bool _862;
        if (_855)
        {
            _862 = (winsel & 16u) != 0u;
        }
        else
        {
            _862 = _855;
        }
        if (_862)
        {
            col2 = col1;
            mask2 = mask1 << 8;
            col1 = ivec4(layercol[4] * 255.0) >> ivec4(2, 2, 2, 3);
            mask1 = 16;
            specialcase = objflags.x != 0;
        }
    }
    int effect = 0;
    int evy = _797.uBlendCoef.z;
    bool _890;
    if (specialcase)
    {
        _890 = (_797.uBlendCnt & mask2) != 0;
    }
    else
    {
        _890 = specialcase;
    }
    int eva;
    int evb;
    if (_890)
    {
        if (mask1 == 1)
        {
            effect = 4;
            eva = (col1.w & 31) + 1;
            evb = 32 - eva;
        }
        else
        {
            if (objflags.x == 1)
            {
                effect = 1;
                eva = _797.uBlendCoef.x;
                evb = _797.uBlendCoef.y;
            }
            else
            {
                effect = 1;
                eva = col1.w;
                evb = 16 - eva;
            }
        }
    }
    else
    {
        bool _925 = (_797.uBlendCnt & mask1) != 0;
        bool _932;
        if (_925)
        {
            _932 = (winsel & 32u) != 0u;
        }
        else
        {
            _932 = _925;
        }
        if (_932)
        {
            effect = _797.uBlendEffect;
            if (effect == 1)
            {
                if ((_797.uBlendCnt & mask2) != 0)
                {
                    eva = _797.uBlendCoef.x;
                    evb = _797.uBlendCoef.y;
                }
                else
                {
                    effect = 0;
                }
            }
        }
    }
    if (effect == 1)
    {
        col1 = (((col1 * ivec4(eva)) + (col2 * ivec4(evb))) + ivec4(8)) >> ivec4(4);
        col1 = min(col1, ivec4(63));
    }
    else
    {
        if (effect == 2)
        {
            col1 += ((((ivec4(63) - col1) * ivec4(evy)) + ivec4(8)) >> ivec4(4));
        }
        else
        {
            if (effect == 3)
            {
                col1 -= (((col1 * ivec4(evy)) + ivec4(7)) >> ivec4(4));
            }
            else
            {
                if (effect == 4)
                {
                    col1 = (((col1 * ivec4(eva)) + (col2 * ivec4(evb))) + ivec4(16)) >> ivec4(5);
                }
            }
        }
    }
    return vec4(vec3(col1.xyz << ivec3(2)) / vec3(255.0), 1.0);
}

void main()
{
    MosaicX = 0;
    highp vec4 _1039 = CompositeLayers();
    oColor = _1039;
}

