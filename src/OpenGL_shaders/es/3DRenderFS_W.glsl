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
} _46;

uniform highp usampler2DArray CurTexture;
uniform highp sampler2DArray Capture128Texture;
uniform highp sampler2DArray Capture256Texture;
uniform int uRenderMode;

in highp vec4 fColor;
flat in ivec3 fPolygonAttr;
in highp vec2 fTexcoord;
out highp vec4 oColor;
out highp vec4 oAttr;
in highp float fZ;

highp vec4 FinalColor()
{
    highp vec4 vcol = fColor;
    int blendmode = (fPolygonAttr.x >> 4) & 3;
    if (blendmode == 2)
    {
        if ((_46.uDispCnt & 2) == 0)
        {
            highp vec3 tooncolor = _46.uToonColors[int(vcol.x * 31.0)].xyz;
            vcol.x = tooncolor.x;
            vcol.y = tooncolor.y;
            vcol.z = tooncolor.z;
        }
        else
        {
            highp vec4 _79 = vcol;
            vcol.x = _79.xxx.x;
            vcol.y = _79.xxx.y;
            vcol.z = _79.xxx.z;
        }
    }
    highp vec4 col;
    if (fPolygonAttr.y == 65535)
    {
        col = vcol;
    }
    else
    {
        highp vec3 texcoord = vec3(fTexcoord, float(fPolygonAttr.y));
        highp vec4 tcol;
        if (fPolygonAttr.z == 0)
        {
            tcol = vec4(texture(CurTexture, texcoord)) / vec4(63.0, 63.0, 63.0, 31.0);
        }
        else
        {
            if (fPolygonAttr.z == 1)
            {
                tcol = texture(Capture128Texture, texcoord);
            }
            else
            {
                tcol = texture(Capture256Texture, texcoord);
            }
        }
        if ((blendmode & 1) != 0)
        {
            highp vec3 _160 = (tcol.xyz * tcol.w) + (vcol.xyz * (1.0 - tcol.w));
            col.x = _160.x;
            col.y = _160.y;
            col.z = _160.z;
            col.w = vcol.w;
        }
        else
        {
            col = vcol * tcol;
        }
    }
    if (blendmode == 2)
    {
        if ((_46.uDispCnt & 2) != 0)
        {
            highp vec3 tooncolor_1 = _46.uToonColors[int(vcol.x * 31.0)].xyz;
            highp vec4 _192 = col;
            highp vec3 _197 = min(_192.xyz + tooncolor_1, vec3(1.0));
            col.x = _197.x;
            col.y = _197.y;
            col.z = _197.z;
        }
    }
    return col;
}

void main()
{
    if (uRenderMode == 2)
    {
        oColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    else
    {
        highp vec4 col = FinalColor();
        if (uRenderMode == 0)
        {
            if (col.w < 0.983870983123779296875)
            {
                discard;
            }
            oAttr.x = float((fPolygonAttr.x >> 24) & 63) / 63.0;
            oAttr.y = 0.0;
            oAttr.z = float((fPolygonAttr.x >> 15) & 1);
            oAttr.w = 1.0;
        }
        else
        {
            if (col.w < 0.01612903177738189697265625)
            {
                discard;
            }
            if (col.w >= 0.983870983123779296875)
            {
                discard;
            }
            oAttr.z = 0.0;
            oAttr.w = 1.0;
        }
        oColor = col;
    }
    gl_FragDepth = fZ;
}

