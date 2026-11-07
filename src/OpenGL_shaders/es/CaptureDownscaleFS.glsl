#version 320 es
precision highp float;
precision highp int;

uniform highp sampler2DArray InputTex;
uniform int uInputLayer;

in highp vec2 fTexcoord;
out highp vec4 oColor;

void main()
{
    ivec4 col = ivec4(texture(InputTex, vec3(fTexcoord, float(uInputLayer))) * 255.0);
    highp vec3 _44 = vec3(col.xyz >> ivec3(3)) / vec3(31.0);
    oColor.x = _44.x;
    oColor.y = _44.y;
    oColor.z = _44.z;
    oColor.w = float(int(col.w > 0));
}

