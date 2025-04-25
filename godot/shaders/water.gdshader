shader_type spatial;
render_mode blend_mix,depth_prepass_alpha,cull_back;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;

uniform float depth_fade_distance : hint_range(0.0, 10.0) = 4.5;
uniform float absorbance : hint_range(0.0, 2.0) = 0.635;

uniform vec3 shallow_color : source_color = vec3(0.217, 0.537, 0.785);
uniform vec3 deep_color : source_color = vec3(0.0, 0.25, 0.45);

uniform float foam_amount : hint_range(0.0, 2.0) = 0.35;
uniform vec3 foam_color : source_color = vec3(1);
uniform float foam_intensity : hint_range(1.0, 3.0) = 2;
uniform sampler2D foam_noise : hint_default_white;

uniform float roughness : hint_range(0.0, 1.0) = 0.045;

uniform sampler2D wave_texture;
uniform float wave_scale = 32.0;
uniform float height_scale : hint_range(1.0, 5.0) = 1.155;
varying float wave_height;
varying vec3 uv_world_pos;

uniform sampler2D normal1;
uniform vec2 wave_dir1 = vec2(3.0, 3.0);
uniform sampler2D normal2;
uniform vec2 wave_dir2 = vec2(-3.0, 1.0);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.004;
uniform float wave_amplitude1 = 2.0;
uniform float wave_amplitude2 = 0.5;

uniform float shine_strength : hint_range(0.0, 1.0) = 0.214;
uniform float shine_shininess : hint_range(5, 32.0) = 18.0;
uniform float shadow : hint_range(0.75, 1.25) = 1.0;
uniform float shadow_width : hint_range(0.001, 0.5) = 0.18;

uniform int normal_map_w : hint_range(1, 512) = 256;


vec3 screen(vec3 base, vec3 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec2 round_to_pixel(vec2 i, int width) {
    float denom = 1.0 / float(width);
    float _x = i.x + abs(mod(i.x, denom) - denom);
    float _y = i.y + abs(mod(i.y, denom) - denom);
    return vec2(_x, _y);
}

void vertex() {
	uv_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave_height = texture(wave_texture, uv_world_pos.xz / wave_scale + TIME * wave_speed).r;
	float wave2 = texture(wave_texture, (uv_world_pos.xz + vec2(0.3, 0.476)) / wave_scale - TIME * wave_speed).r;
	VERTEX.y += (wave_height * wave_amplitude1 + wave2 * wave_amplitude2) * height_scale;
}

void fragment()
{
	// Depth texture magic
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float vertical_depth = vertex_y - depth_texture_y;

	// Changes the color of geometry behind it as the water gets deeper
	float depth_fade_blend = exp(-vertical_depth / depth_fade_distance);
	depth_fade_blend = clamp(depth_fade_blend, 0.0, 1.0);

	// Makes the water more transparent as it gets more shallow
	float alpha_blend = -vertical_depth * absorbance;
	alpha_blend = clamp(1.0 - exp(alpha_blend), 0.0, 1.0);

	// Enhanced foam with noise texture and increased brightness
	vec2 foam_uv = uv_world_pos.xz / wave_scale;
	float foam_noise_sample = texture(foam_noise, foam_uv + TIME * wave_speed * 0.5).r;
	float foam_edge = clamp(1.0 - (vertical_depth / foam_amount), 0.0, 1.0);
	float foam_blend = foam_edge * foam_noise_sample * foam_intensity;
	vec3 foam = foam_blend * foam_color;

	// Mix them all together
	vec3 color_out = mix(deep_color, shallow_color, depth_fade_blend);
	color_out = screen(color_out, foam);

	// Pixel-perfect UV sampling for normals
	vec2 pixel_uv = round_to_pixel(uv_world_pos.xz / wave_scale, normal_map_w);
	vec2 normal_offset1 = (TIME * wave_dir1) * wave_speed;
	vec2 normal_offset2 = (TIME * wave_dir2) * wave_speed;
	vec3 normal1_sample = texture(normal1, pixel_uv + normal_offset1).rgb;
	vec3 normal2_sample = texture(normal2, pixel_uv + normal_offset2).rgb;
	vec3 normal_blend = mix(normal1_sample, normal2_sample, 0.5);

	ALBEDO = color_out;
	ALPHA = alpha_blend;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
}

void light() {
    vec3 H = normalize(VIEW + LIGHT);
    float NdotH = dot(NORMAL, H);

    // Specular calculation
    float specular_amount = max(pow(NdotH, shine_shininess * shine_shininess), 0.0) * ATTENUATION;
    SPECULAR_LIGHT += shine_strength * specular_amount * LIGHT_COLOR;

    float NdotL = dot(NORMAL, LIGHT) * ATTENUATION;
    NdotL = smoothstep(shadow - shadow_width, shadow + shadow_width, NdotL);

    DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO * NdotL;
}