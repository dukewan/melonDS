#version 320 es

layout(std140) uniform uConfig
{
    vec2 uScreenSize;
    int uDispCnt;
    vec4 uToonColors[32];
    vec4 uEdgeColors[8];
    vec4 uFogColor;
    float uFogDensity[34];
    int uFogOffset;
    int uFogShift;
} _45;

in ivec3 vPolygonAttr;
in uvec4 vPosition;
out float fZ;
in ivec2 vTexcoord;
out vec4 fColor;
in uvec4 vColor;
out vec2 fTexcoord;
flat out ivec3 fPolygonAttr;

void main()
{
    int attr = vPolygonAttr.x;
    int zshift = (attr >> 16) & 31;
    vec2 _53 = ((vec2(vPosition.xy) * 2.0) / _45.uScreenSize) - vec2(1.0);
    vec4 fpos;
    fpos.x = _53.x;
    fpos.y = _53.y;
    fZ = float(vPosition.z << uint(zshift)) / 16777216.0;
    fpos.z = 0.0;
    fpos.w = float(vPosition.w) / 65536.0;
    float _81 = fpos.w;
    vec4 _83 = fpos;
    vec3 _85 = _83.xyz * _81;
    fpos.x = _85.x;
    fpos.y = _85.y;
    fpos.z = _85.z;
    int texwidth = vPolygonAttr.z & 65535;
    int texheight = (vPolygonAttr.z >> 16) & 65535;
    vec2 texfactor = vec2(1.0) / (vec2(float(texwidth), float(texheight)) * 16.0);
    vec2 texcoord = vec2(vTexcoord);
    int capyoffset = vPolygonAttr.y >> 16;
    int attrz = 0;
    if (capyoffset != (-1))
    {
        texcoord.y += float(capyoffset);
        if (texwidth == 128)
        {
            attrz = 1;
        }
        else
        {
            attrz = 2;
        }
    }
    fColor = vec4(vColor) / vec4(255.0, 255.0, 255.0, 31.0);
    fTexcoord = texcoord * texfactor;
    fPolygonAttr = ivec3(vPolygonAttr.x, vPolygonAttr.y & 65535, attrz);
    gl_Position = fpos;
}

