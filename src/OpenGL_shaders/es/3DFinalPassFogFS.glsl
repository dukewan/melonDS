#version 320 es
precision highp float;
precision highp int;

layout(std140) uniform uConfig
{
    highp vec2 uScreenSize;
    int uDispCnt;
    highp vec4 uToonColors[32];
    highp vec4 uEdgeColors[8];
    highp vec4 uFogColor;
    highp float uFogDensity[34];
    int uFogOffset;
    int uFogShift;
} _31;

uniform highp sampler2D DepthBuffer;
uniform highp sampler2D AttrBuffer;

out highp vec4 oColor;

highp vec4 CalculateFog(highp float depth)
{
    int idepth = int(depth * 16777216.0);
    int densityid;
    int densityfrac;
    if (idepth < _31.uFogOffset)
    {
        densityid = 0;
        densityfrac = 0;
    }
    else
    {
        uint udepth = uint(idepth);
        udepth -= uint(_31.uFogOffset);
        udepth = (udepth >> uint(2)) << uint(_31.uFogShift);
        densityid = int(udepth >> uint(17));
        if (densityid >= 32)
        {
            densityid = 32;
            densityfrac = 0;
        }
        else
        {
            densityfrac = int(udepth & 131071u);
        }
    }
    highp float density = mix(_31.uFogDensity[densityid], _31.uFogDensity[densityid + 1], float(densityfrac) / 131072.0);
    return vec4(density);
}

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.xy);
    highp vec4 ret = vec4(0.0);
    highp vec4 depth = texelFetch(DepthBuffer, coord, 0);
    highp vec4 attr = texelFetch(AttrBuffer, coord, 0);
    if (attr.z != 0.0)
    {
        highp float param = depth.x;
        ret = CalculateFog(param);
    }
    oColor = ret;
}

