#version 320 es

layout(std140) uniform ubCaptureConfig
{
    vec2 uInvCaptureSize;
    int uSrcALayer;
    int uSrcBLayer;
    int uSrcBOffset;
    int uDstMode;
    ivec2 uBlendFactors;
    vec4 uSrcAOffset[48];
    float uSrcBColorFactor;
} _22;

in ivec2 vPosition;
out vec4 fTexcoord;
in ivec2 vTexcoord;

void main()
{
    vec2 pos = vec2(vPosition) * _22.uInvCaptureSize.xx;
    gl_Position = vec4((pos * 2.0) - vec2(1.0), 0.0, 1.0);
    vec2 _53 = vec2(vTexcoord) / vec2(256.0, 192.0);
    fTexcoord.x = _53.x;
    fTexcoord.y = _53.y;
    fTexcoord.z = float(vTexcoord.y);
    fTexcoord.w = float(vTexcoord.y + _22.uSrcBOffset) / 256.0;
}

