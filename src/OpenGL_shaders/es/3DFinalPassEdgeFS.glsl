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
} _239;

uniform highp sampler2D DepthBuffer;
uniform highp sampler2D AttrBuffer;

out highp vec4 oColor;

bool isless(highp float a, highp float b)
{
    return a < b;
}

bool isgood(highp vec4 attr, highp float depth, int refPolyID, highp float refDepth)
{
    int polyid = int(attr.x * 63.0);
    bool _48 = polyid != refPolyID;
    bool _56;
    if (_48)
    {
        highp float param = refDepth;
        highp float param_1 = depth;
        _56 = isless(param, param_1);
    }
    else
    {
        _56 = _48;
    }
    if (_56)
    {
        return true;
    }
    return false;
}

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.xy);
    int scale = 1;
    highp vec4 ret = vec4(0.0);
    highp vec4 depth = texelFetch(DepthBuffer, coord, 0);
    highp vec4 attr = texelFetch(AttrBuffer, coord, 0);
    int polyid = int(attr.x * 63.0);
    if (attr.y != 0.0)
    {
        highp vec4 depthU = texelFetch(DepthBuffer, coord + ivec2(0, -scale), 0);
        highp vec4 attrU = texelFetch(AttrBuffer, coord + ivec2(0, -scale), 0);
        highp vec4 depthD = texelFetch(DepthBuffer, coord + ivec2(0, scale), 0);
        highp vec4 attrD = texelFetch(AttrBuffer, coord + ivec2(0, scale), 0);
        highp vec4 depthL = texelFetch(DepthBuffer, coord + ivec2(-scale, 0), 0);
        highp vec4 attrL = texelFetch(AttrBuffer, coord + ivec2(-scale, 0), 0);
        highp vec4 depthR = texelFetch(DepthBuffer, coord + ivec2(scale, 0), 0);
        highp vec4 attrR = texelFetch(AttrBuffer, coord + ivec2(scale, 0), 0);
        highp vec4 param = attrU;
        highp float param_1 = depthU.x;
        int param_2 = polyid;
        highp float param_3 = depth.x;
        bool _183 = isgood(param, param_1, param_2, param_3);
        bool _198;
        if (!_183)
        {
            highp vec4 param_4 = attrD;
            highp float param_5 = depthD.x;
            int param_6 = polyid;
            highp float param_7 = depth.x;
            _198 = isgood(param_4, param_5, param_6, param_7);
        }
        else
        {
            _198 = _183;
        }
        bool _213;
        if (!_198)
        {
            highp vec4 param_8 = attrL;
            highp float param_9 = depthL.x;
            int param_10 = polyid;
            highp float param_11 = depth.x;
            _213 = isgood(param_8, param_9, param_10, param_11);
        }
        else
        {
            _213 = _198;
        }
        bool _228;
        if (!_213)
        {
            highp vec4 param_12 = attrR;
            highp float param_13 = depthR.x;
            int param_14 = polyid;
            highp float param_15 = depth.x;
            _228 = isgood(param_12, param_13, param_14, param_15);
        }
        else
        {
            _228 = _213;
        }
        if (_228)
        {
            ret.x = _239.uEdgeColors[polyid >> 3].xyz.x;
            ret.y = _239.uEdgeColors[polyid >> 3].xyz.y;
            ret.z = _239.uEdgeColors[polyid >> 3].xyz.z;
            if ((_239.uDispCnt & 16) != 0)
            {
                ret.w = 0.5;
            }
            else
            {
                ret.w = 1.0;
            }
        }
    }
    oColor = ret;
}

