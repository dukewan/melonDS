#version 320 es
precision highp float;
precision highp int;

struct sBGConfig
{
    ivec2 Size;
    int Type;
    int PalOffset;
    int TileOffset;
    int MapOffset;
    uint Clamp;
};

layout(std140) uniform ubBGConfig
{
    int uVRAMMask;
    sBGConfig uBGConfig[4];
} _38;

uniform highp sampler2D PalTex;
uniform highp usampler2D VRAMTex;
uniform int uCurBG;

out highp vec4 oColor;
in highp vec2 fTexcoord;

int VRAMRead16(int addr)
{
    ivec2 coord = ivec2(addr & 1023, (addr >> 10) & _38.uVRAMMask);
    int lo = int(texelFetch(VRAMTex, coord, 0).x);
    int hi = int(texelFetch(VRAMTex, coord + ivec2(1, 0), 0).x);
    return lo | (hi << 8);
}

int VRAMRead8(int addr)
{
    ivec2 coord = ivec2(addr & 1023, (addr >> 10) & _38.uVRAMMask);
    int val = int(texelFetch(VRAMTex, coord, 0).x);
    return val;
}

highp vec4 GetBGPalEntry(int layer, int pal, int id)
{
    ivec2 coord = ivec2(id, _38.uBGConfig[layer].PalOffset + pal);
    highp vec4 col = texelFetch(PalTex, coord, 0);
    highp vec4 _61 = col;
    highp vec3 _63 = _61.xyz * 0.984126985073089599609375;
    col.x = _63.x;
    col.y = _63.y;
    col.z = _63.z;
    col.y += ((col.w * 1.0) / 63.0);
    return col;
}

highp vec4 GetBGLayerPixel(int layer, ivec2 coord)
{
    highp vec4 ret;
    if (_38.uBGConfig[layer].Type == 0)
    {
        int mapoffset = (_38.uBGConfig[layer].MapOffset + (((coord.x >> 3) & 31) << 1)) + (((coord.y >> 3) & 31) << 6);
        if (_38.uBGConfig[layer].Size.y == 512)
        {
            if (_38.uBGConfig[layer].Size.x == 512)
            {
                mapoffset += ((((coord.x >> 8) & 1) << 11) + (((coord.y >> 8) & 1) << 12));
            }
            else
            {
                mapoffset += (((coord.y >> 8) & 1) << 11);
            }
        }
        else
        {
            if (_38.uBGConfig[layer].Size.x == 512)
            {
                mapoffset += (((coord.x >> 8) & 1) << 11);
            }
        }
        int param = mapoffset;
        int mapval = VRAMRead16(param);
        int tileoffset = (_38.uBGConfig[layer].TileOffset << 1) + ((mapval & 1023) << 6);
        if ((mapval & 1024) != 0)
        {
            tileoffset += (7 - (coord.x & 7));
        }
        else
        {
            tileoffset += (coord.x & 7);
        }
        if ((mapval & 2048) != 0)
        {
            tileoffset += ((7 - (coord.y & 7)) << 3);
        }
        else
        {
            tileoffset += ((coord.y & 7) << 3);
        }
        int param_1 = tileoffset >> 1;
        int col = VRAMRead8(param_1);
        if ((tileoffset & 1) != 0)
        {
            col = col >> 4;
        }
        else
        {
            col &= 15;
        }
        col += ((mapval >> 12) << 4);
        int param_2 = layer;
        int param_3 = 0;
        int param_4 = col;
        ret = GetBGPalEntry(param_2, param_3, param_4);
        ret.w = float(((col & 15) == 0) ? 0 : 1);
    }
    else
    {
        if (_38.uBGConfig[layer].Type == 1)
        {
            int mapoffset_1 = (_38.uBGConfig[layer].MapOffset + (((coord.x >> 3) & 31) << 1)) + (((coord.y >> 3) & 31) << 6);
            if (_38.uBGConfig[layer].Size.y == 512)
            {
                if (_38.uBGConfig[layer].Size.x == 512)
                {
                    mapoffset_1 += ((((coord.x >> 8) & 1) << 11) + (((coord.y >> 8) & 1) << 12));
                }
                else
                {
                    mapoffset_1 += (((coord.y >> 8) & 1) << 11);
                }
            }
            else
            {
                if (_38.uBGConfig[layer].Size.x == 512)
                {
                    mapoffset_1 += (((coord.x >> 8) & 1) << 11);
                }
            }
            int param_5 = mapoffset_1;
            int mapval_1 = VRAMRead16(param_5);
            int tileoffset_1 = _38.uBGConfig[layer].TileOffset + ((mapval_1 & 1023) << 6);
            if ((mapval_1 & 1024) != 0)
            {
                tileoffset_1 += (7 - (coord.x & 7));
            }
            else
            {
                tileoffset_1 += (coord.x & 7);
            }
            if ((mapval_1 & 2048) != 0)
            {
                tileoffset_1 += ((7 - (coord.y & 7)) << 3);
            }
            else
            {
                tileoffset_1 += ((coord.y & 7) << 3);
            }
            int param_6 = tileoffset_1;
            int col_1 = VRAMRead8(param_6);
            int _436;
            if (_38.uBGConfig[layer].PalOffset != 0)
            {
                _436 = mapval_1 >> 12;
            }
            else
            {
                _436 = 0;
            }
            int pal = _436;
            int param_7 = layer;
            int param_8 = pal;
            int param_9 = col_1;
            ret = GetBGPalEntry(param_7, param_8, param_9);
            ret.w = float((col_1 == 0) ? 0 : 1);
        }
        else
        {
            if (_38.uBGConfig[layer].Type == 2)
            {
                int mapoffset_2 = (_38.uBGConfig[layer].MapOffset + (coord.x >> 3)) + ((coord.y >> 3) * (_38.uBGConfig[layer].Size.x >> 3));
                int param_10 = mapoffset_2;
                int mapval_2 = VRAMRead8(param_10);
                int tileoffset_2 = _38.uBGConfig[layer].TileOffset + (mapval_2 << 6);
                tileoffset_2 += ((coord.y & 7) << 3);
                tileoffset_2 += (coord.x & 7);
                int param_11 = tileoffset_2;
                int col_2 = VRAMRead8(param_11);
                int param_12 = layer;
                int param_13 = 0;
                int param_14 = col_2;
                ret = GetBGPalEntry(param_12, param_13, param_14);
                ret.w = float((col_2 == 0) ? 0 : 1);
            }
            else
            {
                if (_38.uBGConfig[layer].Type == 3)
                {
                    int mapoffset_3 = _38.uBGConfig[layer].MapOffset + (((coord.x >> 3) + ((coord.y >> 3) * (_38.uBGConfig[layer].Size.x >> 3))) << 1);
                    int param_15 = mapoffset_3;
                    int mapval_3 = VRAMRead16(param_15);
                    int tileoffset_3 = _38.uBGConfig[layer].TileOffset + ((mapval_3 & 1023) << 6);
                    if ((mapval_3 & 1024) != 0)
                    {
                        tileoffset_3 += (7 - (coord.x & 7));
                    }
                    else
                    {
                        tileoffset_3 += (coord.x & 7);
                    }
                    if ((mapval_3 & 2048) != 0)
                    {
                        tileoffset_3 += ((7 - (coord.y & 7)) << 3);
                    }
                    else
                    {
                        tileoffset_3 += ((coord.y & 7) << 3);
                    }
                    int param_16 = tileoffset_3;
                    int col_3 = VRAMRead8(param_16);
                    int _598;
                    if (_38.uBGConfig[layer].PalOffset != 0)
                    {
                        _598 = mapval_3 >> 12;
                    }
                    else
                    {
                        _598 = 0;
                    }
                    int pal_1 = _598;
                    int param_17 = layer;
                    int param_18 = pal_1;
                    int param_19 = col_3;
                    ret = GetBGPalEntry(param_17, param_18, param_19);
                    ret.w = float((col_3 == 0) ? 0 : 1);
                }
                else
                {
                    if (_38.uBGConfig[layer].Type == 4)
                    {
                        int mapoffset_4 = (_38.uBGConfig[layer].MapOffset + coord.x) + (coord.y * _38.uBGConfig[layer].Size.x);
                        int param_20 = mapoffset_4;
                        int col_4 = VRAMRead8(param_20);
                        int param_21 = layer;
                        int param_22 = 0;
                        int param_23 = col_4;
                        ret = GetBGPalEntry(param_21, param_22, param_23);
                        ret.w = float((col_4 == 0) ? 0 : 1);
                    }
                    else
                    {
                        if (_38.uBGConfig[layer].Type == 5)
                        {
                            int mapoffset_5 = _38.uBGConfig[layer].MapOffset + ((coord.x + (coord.y * _38.uBGConfig[layer].Size.x)) << 1);
                            int param_24 = mapoffset_5;
                            int col_5 = VRAMRead16(param_24);
                            ret.x = float((col_5 << 1) & 62) / 63.0;
                            ret.y = float((col_5 >> 4) & 62) / 63.0;
                            ret.z = float((col_5 >> 9) & 62) / 63.0;
                            ret.w = float(col_5 >> 15);
                        }
                    }
                }
            }
        }
    }
    return ret;
}

void main()
{
    int param = uCurBG;
    ivec2 param_1 = ivec2(fTexcoord);
    oColor = GetBGLayerPixel(param, param_1);
}

