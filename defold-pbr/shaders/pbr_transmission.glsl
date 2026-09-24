#ifndef DEFOLD_PBR_TRANSMISSION
#define DEFOLD_PBR_TRANSMISSION

// Define PBR_TRANSMISSION in the root fragment shader before including this file.
#include "/defold-pbr/shaders/pbr_lighting.glsl"

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
    if (pbrTransmission.transmissionTextures.x > 0.5)
    {
        transmission *= texture(PbrTransmission_transmissionTexture, var_texcoord0).r;
    }
    transmission = clamp(transmission, 0.0, 1.0) * (1.0 - material.metallic);

    if (transmission <= 0.0 || params.unlit)
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
