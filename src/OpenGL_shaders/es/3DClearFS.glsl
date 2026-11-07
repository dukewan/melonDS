#version 320 es
precision highp float;
precision highp int;

uniform uvec4 uColor;
uniform uint uOpaquePolyID;
uniform uint uFogFlag;

out highp vec4 oColor;
out highp vec4 oAttr;

void main()
{
    oColor = vec4(uColor) / vec4(31.0);
    oAttr.x = float(uOpaquePolyID) / 63.0;
    oAttr.y = 0.0;
    oAttr.z = float(uFogFlag);
    oAttr.w = 1.0;
}

