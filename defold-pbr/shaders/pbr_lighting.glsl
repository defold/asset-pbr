#ifndef DEFOLD_PBR_LIGHTING
#define DEFOLD_PBR_LIGHTING

#include "/defold-pbr/shaders/pbr_brdf.glsl"
#include "/defold-pbr/shaders/pbr_inputs.glsl"

/*
 * Light accumulation and composition for Defold PBR.
 *
 * Punctual light data comes from Defold's built-in LightBuffer. This layer
 * converts built-in directional, point, and spot lights into PBRLightData,
 * which is intentionally mutable before final composition with transmission
 * and volume attenuation.
 */
float range_attenuation(float distance_to_light, float range)
{
    float normalized_distance = distance_to_light / max(range, PBR_EPSILON);
    float attenuation = saturate(1.0 - normalized_distance);
    return attenuation * attenuation;
}

/*
 * Intermediate lighting payload.
 *
 * Extensions can add or modify fields between calculate_pbr_light_data() and
 * composite_pbr_transmission(). For example, image-based lighting can inject
 * irradiance into diffuse and prefiltered reflection into specular.
 */
struct PBRLightData
{
    vec3 diffuse;
    vec3 specular;
    vec3 emissive;
    float occlusion;
    float alpha;
};

/* Creates a neutral lighting payload suitable for accumulation. */
PBRLightData empty_pbr_light_data()
{
    PBRLightData data;
    data.diffuse = vec3(0.0);
    data.specular = vec3(0.0);
    data.emissive = vec3(0.0);
    data.occlusion = 1.0;
    data.alpha = 1.0;
    return data;
}

/* Adds additive light fields from value into total. */
void add_pbr_light_data(inout PBRLightData total, PBRLightData value)
{
    total.diffuse += value.diffuse;
    total.specular += value.specular;
    total.emissive += value.emissive;
}

/* Evaluates one Defold light and returns separated diffuse/specular data. */
PBRLightData evaluate_light(vec4 light_position, vec4 light_color_data, vec4 light_direction_range, vec4 light_params, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    PBRLightData data = empty_pbr_light_data();
    int type = int(light_params.x);
    float intensity = light_params.y;
    vec3 light_color = light_color_data.rgb * intensity;
    vec3 l = vec3(0.0);
    float attenuation = 1.0;

    if (type == LIGHT_DIRECTIONAL)
    {
        l = -world_to_view_dir(light_direction_range.xyz);
    }
    else if (type == LIGHT_POINT)
    {
        vec3 to_light = world_to_view_point(light_position.xyz) - fragment_position;
        float distance_to_light = length(to_light);
        l = to_light / max(distance_to_light, PBR_EPSILON);
        attenuation = range_attenuation(distance_to_light, light_direction_range.w);
    }
    else if (type == LIGHT_SPOT)
    {
        vec3 to_light = world_to_view_point(light_position.xyz) - fragment_position;
        float distance_to_light = length(to_light);
        l = to_light / max(distance_to_light, PBR_EPSILON);
        attenuation = range_attenuation(distance_to_light, light_direction_range.w);

        vec3 spot_dir = world_to_view_dir(light_direction_range.xyz);
        float inner_cos = cos(0.5 * light_params.z - PBR_EPSILON);
        float outer_cos = cos(0.5 * light_params.w);
        float spot = smoothstep(outer_cos, inner_cos, dot(-l, spot_dir));
        attenuation *= spot;
    }

    vec3 diffuse_light;
    vec3 specular_light;
    evaluate_brdf(material, n, v, l, light_color, diffuse_light, specular_light);
    data.diffuse = diffuse_light * attenuation;
    data.specular = specular_light * attenuation;
    return data;
}

/* Accumulates all active Defold punctual lights from light_info/lights[]. */
PBRLightData evaluate_punctual_lighting(MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    int count = int(light_info.w);
    PBRLightData total = empty_pbr_light_data();

    for (int i = 0; i < MAX_LIGHT_COUNT; ++i)
    {
        if (i >= count)
        {
            break;
        }
        add_pbr_light_data(total, evaluate_light(lights[i].position, lights[i].color, lights[i].direction_range, lights[i].params, material, n, v, fragment_position));
    }

    return total;
}

/* Provides a small ambient fallback plus any Defold ambient light color. */
PBRLightData evaluate_constant_indirect(MaterialInfo material)
{
    PBRLightData data = empty_pbr_light_data();
    vec3 ambient = ambient_light() + vec3(0.01);
    data.diffuse = material.diffuseColor * ambient;
    data.specular = material.f0 * ambient * (1.0 - 0.5 * material.perceptualRoughness);
    return data;
}

/*
 * Builds the default lighting payload for the material.
 *
 * This is the preferred injection point for custom lighting code:
 * call this function, mutate the returned PBRLightData, then composite.
 */
PBRLightData calculate_pbr_light_data(PBRParams params, MaterialInfo material, vec3 fragment_position)
{
    PBRLightData data = empty_pbr_light_data();
    data.alpha = material.baseColor.a;

    if (params.unlit)
    {
        data.diffuse = material.baseColor.rgb;
    }
    else
    {
        add_pbr_light_data(data, evaluate_punctual_lighting(material, params.normal, params.view, fragment_position));
        add_pbr_light_data(data, evaluate_constant_indirect(material));
        data.occlusion = get_occlusion(params);
    }

    data.emissive = get_emissive(params);
    return data;
}

/* Converts PBRLightData into a linear RGB color. */
vec3 composite_pbr_light_data(PBRLightData data)
{
    return (data.diffuse + data.specular) * data.occlusion + data.emissive;
}

uniform pbr_transmission_uniforms
{
    highp mat4 mtx_projection;
    highp mat4 mtx_world;
};

uniform sampler2D tex_scene_color;

vec3 volume_transmittance(float distance_travelled)
{
    float attenuation_distance = pbrVolume.attenuationDistance.x;
    if (distance_travelled <= 0.0 || attenuation_distance <= 0.0)
    {
        return vec3(1.0);
    }
    vec3 attenuation_color = clamp(pbrVolume.thicknessFactorAndAttenuationColor.yzw, vec3(0.0), vec3(1.0));
    return pow(attenuation_color, vec3(distance_travelled / attenuation_distance));
}

/*
 * Compose smooth transmission after all lighting, including optional IBL, has
 * been accumulated. The opaque scene texture is already exposed and encoded by
 * to_output(), so exposure applies only to the local lighting contribution.
 * Returns linear RGB for the caller's final to_output() conversion.
 */
vec3 composite_pbr_transmission(PBRParams params, MaterialInfo material, PBRLightData light, float exposure)
{
    float transmission = pbrTransmission.transmissionFactor.x;
    // Opaque and unlit materials do not need transmission textures or scene color.
    if (transmission <= 0.0 || params.unlit || material.metallic >= 1.0)
    {
        return composite_pbr_light_data(light) * exposure;
    }

    if (pbrTransmission.transmissionTextures.x > 0.5)
    {
        transmission *= texture(PbrTransmission_transmissionTexture, var_texcoord0).r;
    }
    transmission = clamp(transmission, 0.0, 1.0) * (1.0 - material.metallic);

    if (transmission <= 0.0)
    {
        return composite_pbr_light_data(light) * exposure;
    }

    float thickness = pbrVolume.thicknessFactorAndAttenuationColor.x;
    if (pbrVolume.volumeTextures.x > 0.5)
    {
        // glTF thickness is linear data in the green channel.
        thickness *= texture(PbrVolume_thicknessTexture, var_texcoord0).g;
    }
    float ior = pbrIor.ior.x >= 1.0 ? pbrIor.ior.x : 1.5;
    vec3 ray = refract(-params.worldView, params.worldNormal, 1.0 / ior);
    // World includes the glTF node and game-object scale.
    vec3 model_scale = vec3(length(mtx_world[0].xyz), length(mtx_world[1].xyz), length(mtx_world[2].xyz));
    ray = normalize(ray) * max(thickness, 0.0) * model_scale;
    vec3 exit_position = var_position.xyz + mat3(var_view) * ray;
    vec4 clip = mtx_projection * vec4(exit_position, 1.0);
    vec2 scene_uv = clip.xy / clip.w * 0.5 + 0.5;

    // The captured scene has already had exposure and output conversion applied.
    vec3 background = to_linear(texture(tex_scene_color, scene_uv)).rgb;
    vec3 fresnel = fresnel_schlick(material.f0, material.f90, clamped_dot(params.normal, params.view));
    vec3 transmitted = background * material.baseColor.rgb * volume_transmittance(length(ray)) * (1.0 - fresnel);

    light.diffuse *= 1.0 - transmission;
    return composite_pbr_light_data(light) * exposure + transmitted * transmission;
}

#endif
