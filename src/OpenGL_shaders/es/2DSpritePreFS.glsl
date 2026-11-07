#version 320 es
precision highp float;
precision highp int;

struct sOAM
{
    ivec2 Position;
    uvec2 Flip;
    ivec2 Size;
    ivec2 BoundSize;
    int OBJMode;
    int Type;
    int PalOffset;
    int TileOffset;
    int TileStride;
    int Rotscale;
    int BGPrio;
    uint Mosaic;
};

layout(std140) uniform ubSpriteConfig
{
    int uVRAMMask;
    ivec4 uRotscale[32];
    sOAM uOAM[128];
} _90;

uniform highp sampler2D PalTex;
uniform highp usampler2D VRAMTex;

out highp vec4 oColor;
flat in int fSpriteIndex;
in highp vec2 fTexcoord;

int VRAMRead8(int addr)
{
    ivec2 coord = ivec2(addr & 1023, (addr >> 10) & _90.uVRAMMask);
    int val = int(texelFetch(VRAMTex, coord, 0).x);
    return val;
}

highp vec4 GetOBJPalEntry(int pal, int id)
{
    ivec2 coord = ivec2(id, pal);
    highp vec4 col = texelFetch(PalTex, coord, 0);
    highp vec4 _46 = col;
    highp vec3 _48 = _46.xyz * 0.984126985073089599609375;
    col.x = _48.x;
    col.y = _48.y;
    col.z = _48.z;
    col.y += ((col.w * 1.0) / 63.0);
    return col;
}

int VRAMRead16(int addr)
{
    ivec2 coord = ivec2(addr & 1023, (addr >> 10) & _90.uVRAMMask);
    int lo = int(texelFetch(VRAMTex, coord, 0).x);
    int hi = int(texelFetch(VRAMTex, coord + ivec2(1, 0), 0).x);
    return lo | (hi << 8);
}

highp vec4 GetSpritePixel(int sprite, ivec2 coord)
{
    highp vec4 ret;
    if (_90.uOAM[sprite].Type == 0)
    {
        int tileoffset = (((_90.uOAM[sprite].TileOffset + ((coord.x >> 3) * 32)) + ((coord.y >> 3) * _90.uOAM[sprite].TileStride)) + ((coord.x & 7) >> 1)) + ((coord.y & 7) << 2);
        int param = tileoffset;
        int col = VRAMRead8(param);
        if ((coord.x & 1) != 0)
        {
            col = col >> 4;
        }
        else
        {
            col &= 15;
        }
        col += _90.uOAM[sprite].PalOffset;
        int param_1 = 0;
        int param_2 = col;
        ret = GetOBJPalEntry(param_1, param_2);
        ret.w = float(((col & 15) == 0) ? 0 : 1);
    }
    else
    {
        if (_90.uOAM[sprite].Type == 1)
        {
            int tileoffset_1 = (((_90.uOAM[sprite].TileOffset + ((coord.x >> 3) * 64)) + ((coord.y >> 3) * _90.uOAM[sprite].TileStride)) + (coord.x & 7)) + ((coord.y & 7) << 3);
            int param_3 = tileoffset_1;
            int col_1 = VRAMRead8(param_3);
            int param_4 = _90.uOAM[sprite].PalOffset;
            int param_5 = col_1;
            ret = GetOBJPalEntry(param_4, param_5);
            ret.w = float((col_1 == 0) ? 0 : 1);
        }
        else
        {
            int tileoffset_2 = (_90.uOAM[sprite].TileOffset + (coord.x * 2)) + (coord.y * _90.uOAM[sprite].TileStride);
            int param_6 = tileoffset_2;
            int col_2 = VRAMRead16(param_6);
            ret.x = float((col_2 << 1) & 62) / 63.0;
            ret.y = float((col_2 >> 4) & 62) / 63.0;
            ret.z = float((col_2 >> 9) & 62) / 63.0;
            ret.w = float(col_2 >> 15);
        }
    }
    return ret;
}

void main()
{
    int param = fSpriteIndex;
    ivec2 param_1 = ivec2(fTexcoord);
    oColor = GetSpritePixel(param, param_1);
}

