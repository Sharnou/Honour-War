shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;

uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform bool use_roughness_texture = false;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_normal_texture = false;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

// Honour War cel-shading controls.
uniform int cuts : hint_range(2, 5) = 3;
uniform float wrap : hint_range(-1.0, 1.0) = 0.0;
uniform float steepness : hint_range(1.0, 100.0) = 50.0;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.65;

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);
    vec3 base_color = albedo.rgb;
    if (use_albedo_texture) {
        base_color *= albedo_tex.rgb;
    }
    ALBEDO = base_color;

    float roughness_value = roughness;
    if (use_roughness_texture) {
        roughness_value *= texture(texture_roughness, UV).r;
    }
    ROUGHNESS = clamp(roughness_value, 0.0, 1.0);

    if (use_normal_texture) {
        NORMAL_MAP = texture(texture_normal, UV).rgb;
        NORMAL_MAP_DEPTH = normal_scale;
    }
}

void light() {
    float ndotl = dot(NORMAL, LIGHT);
    float wrapped = clamp((ndotl + wrap) / (1.0 + abs(wrap)), 0.0, 1.0);
    float scaled = wrapped * float(cuts);
    float band = floor(scaled) / float(cuts);
    float edge = clamp((scaled - floor(scaled)) * steepness, 0.0, 1.0);
    float final_diffuse = clamp(band + edge / float(cuts), 0.0, 1.0);

    DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO * final_diffuse * ATTENUATION;

    float hdotn = dot(normalize(LIGHT + VIEW), NORMAL);
    float shininess = max(1.0, (1.0 - ROUGHNESS) * 100.0);
    float spec = pow(max(0.0, hdotn), shininess);
    float stepped_spec = step(0.5, spec);
    SPECULAR_LIGHT += LIGHT_COLOR * stepped_spec * ATTENUATION * specular_strength * (1.0 - ROUGHNESS);
}
