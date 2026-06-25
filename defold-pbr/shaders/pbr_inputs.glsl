#ifndef DEFOLD_PBR_INPUTS
#define DEFOLD_PBR_INPUTS

/*
 * Shared fragment inputs for the Defold PBR material.
 *
 * The built-in lighting include declares Defold's LightBuffer layout,
 * light_info, lights[], light type constants, and world/view conversion
 * helpers. The root fragment shader must declare var_view and define
 * MAX_LIGHT_COUNT before this file is included.
 */
#ifndef MAX_LIGHT_COUNT
#define MAX_LIGHT_COUNT 8
#endif

in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in mediump vec4 var_color;
in mediump vec3 var_tangent;
in mediump vec3 var_bitangent;
in mediump float var_has_tangent;

out vec4 out_fragColor;

#include "/builtins/materials/lighting.glsl"

#endif
