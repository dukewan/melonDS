#version 320 es

in vec2 vPosition;
out vec2 fTexcoord;

void main()
{
    gl_Position = vec4((vPosition * 2.0) - vec2(1.0), 0.0, 1.0);
    fTexcoord = vPosition;
}

