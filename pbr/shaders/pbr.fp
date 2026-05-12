#version 140

#include "/pbr/shaders/pbr_lighting.glsl"

void main()
{
    PBRParams params = get_pbr_params();

#ifdef PBR_DEBUG_BASE_COLOR_TEXTURE
    out_fragColor = vec4(sample_base_color_texture().rgb, 1.0);
    return;
#endif

#ifdef PBR_DEBUG_METALLIC_ROUGHNESS_TEXTURE
    out_fragColor = vec4(sample_metallic_roughness_texture().rgb, 1.0);
    return;
#endif

#ifdef PBR_DEBUG_NORMAL_TEXTURE
    out_fragColor = vec4(sample_normal_texture().rgb, 1.0);
    return;
#endif

#ifdef PBR_DEBUG_OCCLUSION_TEXTURE
    float debug_occlusion = sample_occlusion_texture().r;
    out_fragColor = vec4(vec3(debug_occlusion), 1.0);
    return;
#endif

#ifdef PBR_DEBUG_EMISSIVE_TEXTURE
    out_fragColor = vec4(sample_emissive_texture().rgb, 1.0);
    return;
#endif

    MaterialInfo material = get_material_info(params);

#ifdef PBR_DEBUG_LIGHT_BUFFER
    out_fragColor = vec4(debug_light_buffer_color(), 1.0);
    return;
#endif

#ifdef PBR_DEBUG_VERTEX_NORMAL
    out_fragColor = vec4(normalize(var_normal) * 0.5 + 0.5, 1.0);
    return;
#endif

    vec3 n = get_normal(params);

#ifdef PBR_DEBUG_SHADED_NORMAL
    out_fragColor = vec4(n * 0.5 + 0.5, 1.0);
    return;
#endif

    vec3 v = normalize(-var_position.xyz);

#ifdef PBR_DEBUG_MATERIAL_FACTORS
    out_fragColor = vec4(material.metallic, material.perceptualRoughness, material.baseColor.r, 1.0);
    return;
#endif

    if (params.doubleSided && dot(n, v) < 0.0)
    {
        n = -n;
    }

#ifdef PBR_DEBUG_LIGHTING_ONLY
    vec3 debug_color = params.unlit ? material.baseColor.rgb : evaluate_punctual_lighting(material, n, v, var_position.xyz);
    out_fragColor = vec4(to_output(debug_color), material.baseColor.a);
    out_fragColor.a = 1.0;
    return;
#endif

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
