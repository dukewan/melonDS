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
} _62;

layout(std140) uniform ubSpriteScanlineConfig
{
    ivec4 uMosaicLine[48];
} _88;

uniform highp sampler2D SpriteTex;
uniform bool uRenderTransparent;
uniform highp sampler2DArray Capture256Tex;
uniform highp sampler2DArray Capture128Tex;

in highp vec2 fTexcoord;
flat in int fSpriteIndex;
in highp vec2 fPosition;
out highp vec4 oColor;
out highp vec4 oFlags;

highp vec4 GetSpritePixel(int sprite, highp vec2 coord)
{
    ivec2 basecoord = ivec2((sprite & 15) * 64, (sprite >> 4) * 64);
    return texelFetch(SpriteTex, basecoord + ivec2(coord), 0);
}

void main()
{
    highp vec4 flags = vec4(0.0);
    highp vec2 coord = fTexcoord;
    if (_62.uOAM[fSpriteIndex].Mosaic != 0u)
    {
        int line = int(fPosition.y);
        int mosline = _88.uMosaicLine[line >> 2][line & 3];
        highp float ymin = 0.0;
        if (_62.uOAM[fSpriteIndex].Rotscale != (-1))
        {
            ymin = (-float(_62.uOAM[fSpriteIndex].Size.y)) / 2.0;
        }
        highp float mosy = coord.y - float(line - mosline);
        if (coord.y >= ymin)
        {
            coord.y = max(mosy, ymin);
        }
    }
    if (_62.uOAM[fSpriteIndex].Rotscale != (-1))
    {
        highp vec2 sprsize = vec2(_62.uOAM[fSpriteIndex].Size);
        highp vec4 rotscale = vec4(_62.uRotscale[_62.uOAM[fSpriteIndex].Rotscale]) / vec4(256.0);
        highp mat2 rsmatrix = mat2(vec2(rotscale.xy), vec2(rotscale.zw));
        coord = (coord * rsmatrix) + (sprsize / vec2(2.0));
        if (any(lessThan(coord, vec2(0.0))))
        {
            discard;
        }
        if (any(greaterThanEqual(coord, sprsize)))
        {
            discard;
        }
    }
    if (uRenderTransparent)
    {
        if (_62.uOAM[fSpriteIndex].Mosaic != 0u)
        {
            flags.y = 1.0;
        }
        flags.w = float(_62.uOAM[fSpriteIndex].BGPrio) / 255.0;
        oColor = vec4(0.0);
        oFlags = flags;
        return;
    }
    highp vec4 col;
    if (_62.uOAM[fSpriteIndex].Type == 3)
    {
        coord += vec2(ivec2(_62.uOAM[fSpriteIndex].TileOffset) >> ivec2(1, 8));
        coord *= 0.0078125;
        col = texture(Capture256Tex, vec3(fract(coord), float(_62.uOAM[fSpriteIndex].TileStride)));
    }
    else
    {
        if (_62.uOAM[fSpriteIndex].Type == 4)
        {
            coord += vec2(ivec2(_62.uOAM[fSpriteIndex].TileOffset) >> ivec2(1, 9));
            coord *= 0.00390625;
            col = texture(Capture256Tex, vec3(fract(coord), float(_62.uOAM[fSpriteIndex].TileStride)));
        }
        else
        {
            int param = fSpriteIndex;
            highp vec2 param_1 = coord;
            col = GetSpritePixel(param, param_1);
        }
    }
    if (col.w == 0.0)
    {
        discard;
    }
    if (_62.uOAM[fSpriteIndex].OBJMode == 2)
    {
        flags.z = 1.0;
    }
    else
    {
        if (_62.uOAM[fSpriteIndex].OBJMode == 1)
        {
            flags.x = 0.0039215688593685626983642578125;
        }
        else
        {
            if (_62.uOAM[fSpriteIndex].OBJMode == 3)
            {
                col.w = float(_62.uOAM[fSpriteIndex].PalOffset) / 31.0;
                flags.x = 0.007843137718737125396728515625;
            }
        }
        if (_62.uOAM[fSpriteIndex].Mosaic != 0u)
        {
            flags.y = 1.0;
        }
        flags.w = float(_62.uOAM[fSpriteIndex].BGPrio) / 255.0;
    }
    oColor = col;
    oFlags = flags;
}

