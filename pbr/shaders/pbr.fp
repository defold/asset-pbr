#version 140

#include "/pbr/shaders/pbr_lighting.glsl"

void main()
{
    PBRParams params = get_pbr_params();
    MaterialInfo material = get_material_info(params);

#ifdef PBR_DEBUG_LIGHT_BUFFER
    out_fragColor = vec4(debug_light_buffer_color(), 1.0);
    return;
#endif

#ifdef PBR_DEBUG_VERTEX_NORMAL
    out_fragColor = vec4(normalize(var_normal) * 0.5 + 0.5, 1.0);
    return;
#endif

#ifdef PBR_DEBUG_TANGENT
    out_fragColor = vec4(normalize(var_tangent) * 0.5 + 0.5, var_has_tangent);
    return;
#endif

#ifdef PBR_DEBUG_BITANGENT
    out_fragColor = vec4(normalize(var_bitangent) * 0.5 + 0.5, var_has_tangent);
    return;
#endif

#ifdef PBR_DEBUG_TANGENT_NORMAL
    out_fragColor = vec4(get_tangent_space_normal(params) * 0.5 + 0.5, 1.0);
    return;
#endif

    vec3 n = get_normal(params);

#ifdef PBR_DEBUG_SHADED_NORMAL
    out_fragColor = vec4(n * 0.5 + 0.5, 1.0);
    return;
#endif

    vec3 v = normalize(-var_position.xyz);

    if (params.doubleSided && dot(n, v) < 0.0)
    {
        n = -n;
    }

    vec3 color = material.baseColor.rgb;
    if (!params.unlit)
    {
        color = evaluate_punctual_lighting(material, n, v, var_position.xyz);
        float occlusion = get_occlusion(params);
        color += evaluate_constant_indirect(material);
        color *= occlusion;
    }

    color += get_emissive(params);
    out_fragColor = vec4(to_output(color), material.baseColor.a);
    out_fragColor.a = 1.0;
}
