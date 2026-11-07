#version 320 es
precision highp float;
precision highp int;

uniform highp vec2 uClearBitmapOffset;
uniform highp usampler2D ClearBitmapColor;
uniform highp usampler2D ClearBitmapDepth;
uniform uint uOpaquePolyID;

in highp vec2 fTexcoord;
out highp vec4 oColor;
out highp vec4 oAttr;

void main()
{
    highp vec2 pos = fTexcoord + uClearBitmapOffset;
    highp vec4 color = vec4(texture(ClearBitmapColor, pos)) / vec4(63.0, 63.0, 63.0, 31.0);
    uint depth = texture(ClearBitmapDepth, pos).x;
    highp float fdepth = float(depth & 16777215u) / 16777216.0;
    oColor = color;
    oAttr.x = float(uOpaquePolyID) / 63.0;
    oAttr.y = 0.0;
    oAttr.z = float(depth >> uint(24));
    oAttr.w = 1.0;
    gl_FragDepth = fdepth;
}

