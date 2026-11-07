#version 320 es

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
} _33;

in int vSpriteIndex;
in ivec2 vPosition;
flat out int fSpriteIndex;
out vec2 fTexcoord;

void main()
{
    ivec2 sprpos = ivec2((vSpriteIndex & 15) * 64, (vSpriteIndex >> 4) * 64);
    ivec2 sprsize = _33.uOAM[vSpriteIndex].Size;
    vec2 vtxpos = vec2(sprpos) + (vec2(vPosition) * vec2(sprsize));
    vec2 fbsize = vec2(1024.0, 512.0);
    gl_Position = vec4(((vtxpos * 2.0) / fbsize) - vec2(1.0), 0.0, 1.0);
    fSpriteIndex = vSpriteIndex;
    fTexcoord = vec2(vPosition) * vec2(sprsize);
}

