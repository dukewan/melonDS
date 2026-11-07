#version 320 es
precision highp float;
precision highp int;

layout(std140) uniform ubFinalPassConfig
{
    uvec4 uScreenSwap[48];
    int uScaleFactor;
    int uAuxLayer;
    int uDispModeA;
    int uDispModeB;
    int uBrightModeA;
    int uBrightModeB;
    int uBrightFactorA;
    int uBrightFactorB;
    highp float uAuxColorFactor;
} _93;

uniform highp sampler2D MainInputTexA;
uniform highp sampler2D MainInputTexB;
uniform highp sampler2DArray AuxInputTex;

in highp vec3 fTexcoord;
out highp vec4 oTopColor;
out highp vec4 oBottomColor;

ivec3 MasterBrightness(inout ivec3 color, int brightmode, int evy)
{
    if (brightmode == 1)
    {
        color += (((ivec3(63) - color) * ivec3(evy)) >> ivec3(4));
    }
    else
    {
        if (brightmode == 2)
        {
            color -= (((color * ivec3(evy)) + ivec3(15)) >> ivec3(4));
        }
    }
    return color;
}

void main()
{
    ivec4 col_main = ivec4(texture(MainInputTexA, fTexcoord.xy, 0.0) * 255.0) >> ivec4(2);
    ivec4 col_sub = ivec4(texture(MainInputTexB, fTexcoord.xy, 0.0) * 255.0) >> ivec4(2);
    ivec3 output_main;
    if (_93.uDispModeA == 0)
    {
        output_main = ivec3(63);
    }
    else
    {
        if (_93.uDispModeA == 1)
        {
            output_main = col_main.xyz;
        }
        else
        {
            output_main = ivec3(texture(AuxInputTex, vec3(fTexcoord.xz, float(_93.uAuxLayer))).xyz * _93.uAuxColorFactor);
        }
    }
    ivec3 output_sub;
    if (_93.uDispModeB == 0)
    {
        output_sub = ivec3(63);
    }
    else
    {
        output_sub = col_sub.xyz;
    }
    if (_93.uDispModeA != 0)
    {
        ivec3 param = output_main;
        int param_1 = _93.uBrightModeA;
        int param_2 = _93.uBrightFactorA;
        ivec3 _158 = MasterBrightness(param, param_1, param_2);
        output_main = _158;
    }
    if (_93.uDispModeB != 0)
    {
        ivec3 param_3 = output_sub;
        int param_4 = _93.uBrightModeB;
        int param_5 = _93.uBrightFactorB;
        ivec3 _174 = MasterBrightness(param_3, param_4, param_5);
        output_sub = _174;
    }
    output_main = (output_main << ivec3(2)) | (output_main >> ivec3(6));
    output_sub = (output_sub << ivec3(2)) | (output_sub >> ivec3(6));
    int line = int(fTexcoord.y * 192.0);
    bool swapbit = _93.uScreenSwap[line >> 2][line & 3] != 0u;
    if (!swapbit)
    {
        oTopColor = vec4(vec3(output_sub) / vec3(255.0), 1.0);
        oBottomColor = vec4(vec3(output_main) / vec3(255.0), 1.0);
    }
    else
    {
        oTopColor = vec4(vec3(output_main) / vec3(255.0), 1.0);
        oBottomColor = vec4(vec3(output_sub) / vec3(255.0), 1.0);
    }
}

