#version 320 es

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
} _40;

uniform int uCurBG;

in vec2 vPosition;
out vec2 fTexcoord;

void main()
{
    gl_Position = vec4((vPosition * 2.0) - vec2(1.0), 0.0, 1.0);
    fTexcoord = vPosition * vec2(_40.uBGConfig[uCurBG].Size);
}

