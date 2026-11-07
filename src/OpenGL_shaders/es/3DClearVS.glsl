#version 320 es

uniform uint uDepth;

in vec2 vPosition;

void main()
{
    float fdepth = (float(uDepth) / 8388608.0) - 1.0;
    gl_Position = vec4(vPosition, fdepth, 1.0);
}

