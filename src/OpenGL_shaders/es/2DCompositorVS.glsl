#version 320 es

uniform int uScaleFactor;

in vec2 vPosition;
out vec4 fTexcoord;

void main()
{
    gl_Position = vec4((vPosition * 2.0) - vec2(1.0), 0.0, 1.0);
    vec2 _36 = vPosition * vec2(256.0, 192.0);
    fTexcoord.x = _36.x;
    fTexcoord.y = _36.y;
    vec4 _43 = fTexcoord;
    vec2 _49 = _43.xy * float(uScaleFactor);
    fTexcoord.z = _49.x;
    fTexcoord.w = _49.y;
}

