#ifndef TEMPLATE_PBR_LIGHTING
#define TEMPLATE_PBR_LIGHTING

#include "/pbr/shaders/pbr_brdf.glsl"
#include "/pbr/shaders/pbr_inputs.glsl"

vec3 world_to_view_point(vec3 p)
{
    return (var_view * vec4(p, 1.0)).xyz;
}

vec3 world_to_view_dir(vec3 d)
{
    return normalize((var_view * vec4(d, 0.0)).xyz);
}

float range_attenuation(float distance_to_light, float range)
{
    float normalized_distance = distance_to_light / max(range, PBR_EPSILON);
    float attenuation = saturate(1.0 - normalized_distance);
    return attenuation * attenuation;
}

vec3 evaluate_light(vec4 light_position, vec4 light_color_data, vec4 light_direction_range, vec4 light_params, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
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

    return attenuation * evaluate_brdf(material, n, v, l, light_color);
}

void accumulate_light_0(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (0 < count)
    {
        total += evaluate_light(lights[0].position, lights[0].color, lights[0].direction_range, lights[0].params, material, n, v, fragment_position);
    }
}

void accumulate_light_1(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (1 < count)
    {
        total += evaluate_light(lights[1].position, lights[1].color, lights[1].direction_range, lights[1].params, material, n, v, fragment_position);
    }
}

void accumulate_light_2(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (2 < count)
    {
        total += evaluate_light(lights[2].position, lights[2].color, lights[2].direction_range, lights[2].params, material, n, v, fragment_position);
    }
}

void accumulate_light_3(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (3 < count)
    {
        total += evaluate_light(lights[3].position, lights[3].color, lights[3].direction_range, lights[3].params, material, n, v, fragment_position);
    }
}

void accumulate_light_4(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (4 < count)
    {
        total += evaluate_light(lights[4].position, lights[4].color, lights[4].direction_range, lights[4].params, material, n, v, fragment_position);
    }
}

void accumulate_light_5(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (5 < count)
    {
        total += evaluate_light(lights[5].position, lights[5].color, lights[5].direction_range, lights[5].params, material, n, v, fragment_position);
    }
}

void accumulate_light_6(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (6 < count)
    {
        total += evaluate_light(lights[6].position, lights[6].color, lights[6].direction_range, lights[6].params, material, n, v, fragment_position);
    }
}

void accumulate_light_7(inout vec3 total, int count, MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    if (7 < count)
    {
        total += evaluate_light(lights[7].position, lights[7].color, lights[7].direction_range, lights[7].params, material, n, v, fragment_position);
    }
}

vec3 evaluate_punctual_lighting(MaterialInfo material, vec3 n, vec3 v, vec3 fragment_position)
{
    int count = int(lights_count.x);
    vec3 total = vec3(0.0);

    accumulate_light_0(total, count, material, n, v, fragment_position);
    accumulate_light_1(total, count, material, n, v, fragment_position);
    accumulate_light_2(total, count, material, n, v, fragment_position);
    accumulate_light_3(total, count, material, n, v, fragment_position);
    accumulate_light_4(total, count, material, n, v, fragment_position);
    accumulate_light_5(total, count, material, n, v, fragment_position);
    accumulate_light_6(total, count, material, n, v, fragment_position);
    accumulate_light_7(total, count, material, n, v, fragment_position);

    return total;
}

vec3 evaluate_constant_indirect(MaterialInfo material)
{
    vec3 diffuse = material.diffuseColor * 0.03;
    vec3 specular = material.f0 * 0.04 * (1.0 - 0.5 * material.perceptualRoughness);
    return diffuse + specular;
}

vec3 debug_light_buffer_color()
{
    float count = min(lights_count.x / float(MAX_LIGHTS), 1.0);
    vec3 first_type = vec3(0.0);
    if (lights_count.x > 0.5)
    {
        first_type = vec3(lights[0].params.x / 2.0, lights[0].params.y * 0.1, length(lights[0].direction_range.xyz));
    }
    return vec3(count, first_type.y, first_type.z);
}

#endif
