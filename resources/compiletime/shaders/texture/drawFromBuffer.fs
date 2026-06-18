#version 430

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;

layout(std430, binding = 1) readonly restrict buffer colorsInBuffer
{
    int colors[];
};

void main()
{
    ivec2 resolution = textureSize(texture0, 0);
    ivec2 position = ivec2(fragTexCoord * resolution);

    int color = colors[position.y * resolution.y + position.x];
    finalColor.r = color >> 24;
    finalColor.g = (color & 0x00FF0000) >> 16;
    finalColor.b = (color & 0x0000FF00) >> 8;
    finalColor.a = color & 0x000000FF;
}