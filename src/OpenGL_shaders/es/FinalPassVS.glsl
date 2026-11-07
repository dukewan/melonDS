#version 320 es

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
    float uAuxColorFactor;
} _43;

in vec2 vPosition;
out vec3 fTexcoord;

void main()
{
    gl_Position = vec4(vPosition, 0.0, 1.0);
    fTexcoord = (vPosition.xyy + vec3(1.0)) * vec3(0.5, 0.5, 0.375);
}

