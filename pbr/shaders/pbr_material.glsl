#ifndef TEMPLATE_PBR_MATERIAL
#define TEMPLATE_PBR_MATERIAL

#include "/pbr/shaders/pbr_common.glsl"
#include "/pbr/shaders/pbr_inputs.glsl"

uniform sampler2D PbrMaterial_normalTexture;
uniform sampler2D PbrMaterial_occlusionTexture;
uniform sampler2D PbrMaterial_emissiveTexture;

uniform sampler2D PbrMetallicRoughness_baseColorTexture;
uniform sampler2D PbrMetallicRoughness_metallicRoughnessTexture;

struct PbrMetallicRoughness
{
    vec4 baseColorFactor;
    vec4 metallicAndRoughnessFactor;
    vec4 metallicRoughnessTextures;
};

uniform PbrMaterial
{
    vec4 pbrAlphaCutoffAndDoubleSidedAndIsUnlit;
    vec4 pbrCommonTextures;
    PbrMetallicRoughness pbrMetallicRoughness;
};

struct PBRParams
{
    vec4 baseColorFactor;
    float metallicFactor;
    float roughnessFactor;
    float alphaCutoff;
    bool doubleSided;
    bool unlit;
    bool hasBaseColorTexture;
    bool hasMetallicRoughnessTexture;
    bool hasNormalTexture;
    bool hasOcclusionTexture;
    bool hasEmissiveTexture;
};

struct MaterialInfo
{
    vec4 baseColor;
    vec3 diffuseColor;
    vec3 f0;
    vec3 f90;
    float metallic;
    float perceptualRoughness;
    float alphaRoughness;
    float specularWeight;
};

float valid_or(float value, float fallback)
{
    return value == value ? value : fallback;
}

bool is_valid(float value)
{
    return value == value;
}

bool is_valid(vec4 value)
{
    return is_valid(value.x) && is_valid(value.y) && is_valid(value.z) && is_valid(value.w);
}

PBRParams get_pbr_params()
{
    PBRParams params;
    vec4 base_color_factor = pbrMetallicRoughness.baseColorFactor;
    params.baseColorFactor = is_valid(base_color_factor) && base_color_factor.a > 0.0 ? base_color_factor : vec4(1.0);
    params.metallicFactor = valid_or(pbrMetallicRoughness.metallicAndRoughnessFactor.x, 1.0);
    params.roughnessFactor = valid_or(pbrMetallicRoughness.metallicAndRoughnessFactor.y, 1.0);
    params.alphaCutoff = max(valid_or(pbrAlphaCutoffAndDoubleSidedAndIsUnlit.x, 0.0), 0.0);
    params.doubleSided = pbrAlphaCutoffAndDoubleSidedAndIsUnlit.y > 0.5;
    params.unlit = pbrAlphaCutoffAndDoubleSidedAndIsUnlit.z > 0.5;
    params.hasBaseColorTexture = pbrMetallicRoughness.metallicRoughnessTextures.x > 0.5;
    params.hasMetallicRoughnessTexture = pbrMetallicRoughness.metallicRoughnessTextures.y > 0.5;
    params.hasNormalTexture = pbrCommonTextures.x > 0.5;
    params.hasOcclusionTexture = pbrCommonTextures.y > 0.5;
    params.hasEmissiveTexture = pbrCommonTextures.z > 0.5;
    return params;
}

vec4 get_base_color(PBRParams params)
{
    vec4 base_color = params.baseColorFactor;
    if (params.hasBaseColorTexture)
    {
        base_color *= to_linear(texture(PbrMetallicRoughness_baseColorTexture, var_texcoord0));
    }
    return base_color * var_color;
}

vec3 get_tangent_space_normal(PBRParams params)
{
    if (params.hasNormalTexture)
    {
        return normalize(texture(PbrMaterial_normalTexture, var_texcoord0).xyz * 2.0 - 1.0);
    }
    return vec3(0.0, 0.0, 1.0);
}

vec3 get_normal(PBRParams params)
{
    vec3 n = normalize(var_normal);
    if (params.hasNormalTexture && var_has_tangent > 0.5)
    {
        vec3 tangent_normal = get_tangent_space_normal(params);
        n = normalize(mat3(normalize(var_tangent), normalize(var_bitangent), n) * tangent_normal);
    }
    return n;
}

MaterialInfo get_material_info(PBRParams params)
{
    MaterialInfo material;
    material.baseColor = get_base_color(params);
    material.metallic = clamp(params.metallicFactor, 0.0, 1.0);
    material.perceptualRoughness = clamp(params.roughnessFactor, 0.04, 1.0);

    if (params.hasMetallicRoughnessTexture)
    {
        vec4 metallic_roughness = texture(PbrMetallicRoughness_metallicRoughnessTexture, var_texcoord0);
        material.perceptualRoughness *= metallic_roughness.g;
        material.metallic *= metallic_roughness.b;
    }

    material.perceptualRoughness = clamp(material.perceptualRoughness, 0.04, 1.0);
    material.alphaRoughness = material.perceptualRoughness * material.perceptualRoughness;
    material.f0 = mix(vec3(0.04), material.baseColor.rgb, material.metallic);
    material.f90 = vec3(1.0);
    material.diffuseColor = material.baseColor.rgb * (1.0 - material.metallic);
    material.specularWeight = 1.0;
    return material;
}

float get_occlusion(PBRParams params)
{
    if (params.hasOcclusionTexture)
    {
        return texture(PbrMaterial_occlusionTexture, var_texcoord0).r;
    }
    return 1.0;
}

vec3 get_emissive(PBRParams params)
{
    if (params.hasEmissiveTexture)
    {
        return to_linear(texture(PbrMaterial_emissiveTexture, var_texcoord0)).rgb;
    }
    return vec3(0.0);
}

#endif
