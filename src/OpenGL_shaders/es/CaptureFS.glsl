#version 320 es
precision highp float;
precision highp int;

layout(std140) uniform ubCaptureConfig
{
    highp vec2 uInvCaptureSize;
    int uSrcALayer;
    int uSrcBLayer;
    int uSrcBOffset;
    int uDstMode;
    ivec2 uBlendFactors;
    highp vec4 uSrcAOffset[48];
    highp float uSrcBColorFactor;
} _27;

uniform highp sampler2D InputTexA;
uniform highp sampler2DArray InputTexB;

in highp vec4 fTexcoord;
out highp vec4 oColor;

void main()
{
    highp vec2 coordA = fTexcoord.xy;
    highp vec3 coordB = vec3(fTexcoord.xw, float(_27.uSrcBLayer));
    if (_27.uSrcALayer == 1)
    {
        int line = int(fTexcoord.z);
        coordA.x += _27.uSrcAOffset[line >> 2][line & 3];
    }
    ivec4 cap_out;
    if (_27.uDstMode == 0)
    {
        cap_out = ivec4(texture(InputTexA, coordA) * 255.0);
    }
    else
    {
        if (_27.uDstMode == 1)
        {
            cap_out = ivec4(texture(InputTexB, coordB) * _27.uSrcBColorFactor);
        }
        else
        {
            ivec4 srcA = ivec4(texture(InputTexA, coordA) * 255.0) >> ivec4(3);
            ivec4 srcB = ivec4(texture(InputTexB, coordB) * _27.uSrcBColorFactor) >> ivec4(3);
            int eva = _27.uBlendFactors.x;
            int evb = _27.uBlendFactors.y;
            int aa = int(srcA.w > 0);
            int ab = int(srcB.w > 0);
            ivec3 _163 = ((((srcA.xyz * ivec3(aa)) * ivec3(eva)) + ((srcB.xyz * ivec3(ab)) * ivec3(evb))) + ivec3(8)) >> ivec3(4);
            cap_out.x = _163.x;
            cap_out.y = _163.y;
            cap_out.z = _163.z;
            ivec4 _170 = cap_out;
            ivec3 _176 = min(_170.xyz, ivec3(31)) << ivec3(3);
            cap_out.x = _176.x;
            cap_out.y = _176.y;
            cap_out.z = _176.z;
            cap_out.w = ((eva > 0) ? aa : 0) | ((evb > 0) ? ab : 0);
        }
    }
    oColor = vec4(vec3(cap_out.xyz) / vec3(255.0), float(cap_out.w > 0));
}

