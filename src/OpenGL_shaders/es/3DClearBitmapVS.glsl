#version 320 es

out vec2 fTexcoord;
in vec2 vPosition;

void main()
{
    fTexcoord = (vPosition + vec2(1.0)) * vec2(0.5, 0.375);
    gl_Position = vec4(vPosition, 0.0, 1.0);
}

