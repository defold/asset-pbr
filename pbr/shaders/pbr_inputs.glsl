#ifndef TEMPLATE_PBR_INPUTS
#define TEMPLATE_PBR_INPUTS

#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT       1
#define LIGHT_SPOT        2
#define MAX_LIGHTS        8

// Basic debug views. Enable one at a time.
// #define PBR_DEBUG_NO_TEXTURES 1
// #define PBR_DEBUG_LIGHTING_ONLY 1
// #define PBR_DEBUG_LIGHT_BUFFER 1
// #define PBR_DEBUG_VERTEX_NORMAL 1
// #define PBR_DEBUG_SHADED_NORMAL 1
// #define PBR_DEBUG_MATERIAL_FACTORS 1
// #define PBR_DEBUG_BASE_COLOR_TEXTURE 1
// #define PBR_DEBUG_METALLIC_ROUGHNESS_TEXTURE 1
// #define PBR_DEBUG_NORMAL_TEXTURE 1
// #define PBR_DEBUG_OCCLUSION_TEXTURE 1
// #define PBR_DEBUG_EMISSIVE_TEXTURE 1

in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in mediump vec4 var_color;
in mediump vec3 var_tangent;
in mediump vec3 var_bitangent;
in mediump float var_has_tangent;
in mediump mat4 var_view;

out vec4 out_fragColor;

#ifdef EDITOR
uniform Light
{
    vec4 position;
    vec4 color;
    vec4 direction_range;
    vec4 params;
} lights[MAX_LIGHTS];

uniform fs_uniforms
{
    vec4 lights_count;
};
#else
struct Light
{
    vec4 position;
    vec4 color;
    vec4 direction_range;
    vec4 params;
};

uniform LightBuffer
{
    vec4  lights_count;
    Light lights[MAX_LIGHTS];
};
#endif

#endif
