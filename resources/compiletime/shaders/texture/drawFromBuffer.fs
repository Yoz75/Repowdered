#version 430

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;

layout(std430, binding = 1) readonly restrict buffer colorsInBuffer
{
    uint colors[];
};

void main()
{
    ivec2 resolution = textureSize(texture0, 0);
    ivec2 position = ivec2(fragTexCoord * resolution);

    uint color = colors[position.y * resolution.x + position.x];
    finalColor.a = (color >> 24) / 255.0;
    finalColor.b = ((color & 0x00FF0000) >> 16) / 255.0;
    finalColor.g = ((color & 0x0000FF00) >> 8) / 255.0;
    finalColor.r = (color & 0x000000FF) / 255.0;
}