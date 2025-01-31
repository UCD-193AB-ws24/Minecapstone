shader_type spatial;

uniform sampler2D height_map;
uniform sampler2D biome_map;
uniform sampler2D river_mask;
uniform float height_scale = 50.0;

void vertex() {
    vec4 height = texture(height_map, UV);
    VERTEX.y = height.r * height_scale;
}

void fragment() {
    vec4 biome_color = texture(biome_map, UV);
    vec4 river = texture(river_mask, UV);
    
    if (river.r > 0.7) {
        biome_color.rgb = mix(biome_color.rgb, vec3(0.0, 0.3, 1.0), 0.7);
    }
    
    ALBEDO = biome_color.rgb;
    METALLIC = 0.0;
    ROUGHNESS = 0.8;
}