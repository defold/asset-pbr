#version 140

in mediump mat4 var_view;

#define MAX_LIGHT_COUNT 8
#define PBR_TRANSMISSION
#include "/defold-pbr/shaders/pbr_transmission.glsl"

void main()
{
    PBRParams params = get_pbr_params();
    MaterialInfo material = get_material_info(params);
    PBRLightData light = calculate_pbr_light_data(params, material, var_position.xyz);
    vec3 color = composite_pbr_transmission(params, material, light, 1.0);
    out_fragColor = vec4(to_output(color), 1.0);
}
