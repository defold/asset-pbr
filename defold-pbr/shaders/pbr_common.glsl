#ifndef DEFOLD_PBR_COMMON
#define DEFOLD_PBR_COMMON

/*
 * Common scalar, color-space, and clamping helpers shared by the PBR shader
 * modules. The material assumes texture color data is sampled as sRGB-like
 * input and converted to linear space before lighting.
 */
const float PBR_PI = 3.1415926535897932384626433832795;
const float PBR_EPSILON = 0.00001;

float saturate(float value)
{
    return clamp(value, 0.0, 1.0);
}

vec3 saturate(vec3 value)
{
    return clamp(value, vec3(0.0), vec3(1.0));
}

vec4 to_linear(vec4 color)
{
    return vec4(pow(color.rgb, vec3(2.2)), color.a);
}

vec3 to_output(vec3 color)
{
    return pow(saturate(color), vec3(1.0 / 2.2));
}

float clamped_dot(vec3 a, vec3 b)
{
    return saturate(dot(a, b));
}

#endif
