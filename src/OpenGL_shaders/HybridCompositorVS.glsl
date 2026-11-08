#version 140

in vec2 vPosition;
in vec2 vTexcoord;

smooth out vec2 fTexcoord;

void main()
{
    gl_Position = vec4(vPosition, 0.0, 1.0);
    fTexcoord = vTexcoord;
}
