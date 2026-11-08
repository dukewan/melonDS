#version 320 es

in vec2 vPosition;
out vec2 fTexcoord;
in vec2 vTexcoord;

void main()
{
    gl_Position = vec4(vPosition, 0.0, 1.0);
    fTexcoord = vTexcoord;
}

