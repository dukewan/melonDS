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
} _22;

in int vSpriteIndex;
in ivec2 vPosition;
out vec2 fPosition;
flat out int fSpriteIndex;
in ivec2 vTexcoord;
out vec2 fTexcoord;

void main()
{
    vec2 sprsize = vec2(_22.uOAM[vSpriteIndex].BoundSize);
    vec2 fbsize = vec2(256.0, 192.0);
    int totalprio = (_22.uOAM[vSpriteIndex].BGPrio * 128) + vSpriteIndex;
    float z = float(totalprio) / 512.0;
    gl_Position = vec4(((vec2(vPosition) * 2.0) / fbsize) - vec2(1.0), z, 1.0);
    fPosition = vec2(vPosition);
    fSpriteIndex = vSpriteIndex;
    if (_22.uOAM[vSpriteIndex].Rotscale == (-1))
    {
        vec2 tmp = vec2(vTexcoord) * sprsize;
        fTexcoord = mix(tmp, sprsize - tmp, notEqual(_22.uOAM[vSpriteIndex].Flip, uvec2(0u)));
    }
    else
    {
        fTexcoord = (vec2(vTexcoord) * sprsize) - (sprsize / vec2(2.0));
    }
}

