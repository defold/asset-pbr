#version 140

in mediump mat4 var_view;

#define MAX_LIGHT_COUNT 8
#include "/defold-pbr/shaders/pbr_transmission.glsl"

void main()
{
    PBRParams params = get_pbr_params();
    MaterialInfo material = get_material_info(params);

    /*
     * Extension point:
     *   PBRLightData pbr_data = calculate_pbr_light_data(...);
     *   pbr_data.specular += calculate_custom_specular(...);
     *   vec3 color = composite_pbr_transmission(params, material, pbr_data, 1.0);
     */
    PBRLightData pbr_data = calculate_pbr_light_data(params, material, var_position.xyz);
    vec3 color = composite_pbr_transmission(params, material, pbr_data, 1.0);
    out_fragColor = vec4(to_output(color), pbr_data.alpha);
    out_fragColor.a = 1.0;
}
