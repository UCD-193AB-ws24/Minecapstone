shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

// Parameters that can be adjusted in the material inspector
uniform vec4 albedo : source_color = vec4(0.0, 0.7, 1.0, 0.5);
uniform vec4 emission_color : source_color = vec4(0.0, 0.7, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform float fresnel_power : hint_range(1.0, 10.0) = 3.0;
uniform float edge_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform sampler2D noise_texture;
uniform bool enable_scrolling = true;
uniform vec2 scroll_direction = vec2(0.1, 0.3);

varying vec3 vertex_pos;
varying vec3 normal_interp;

void vertex() {
    vertex_pos = VERTEX;
    normal_interp = NORMAL;
}

void fragment() {
    // Base color with transparency
    ALBEDO = albedo.rgb;
    
    // Make the material a bit transparent
    ALPHA = albedo.a;
    
    // Create fresnel effect (edges glow stronger)
    vec3 view_dir = normalize(VIEW);
    float fresnel = pow(1.0 - dot(NORMAL, view_dir), fresnel_power);
    
    // Add scrolling noise effect
    vec2 uv_scrolled = UV;
    if (enable_scrolling) {
        uv_scrolled += scroll_direction * TIME * pulse_speed;
    }
    
    // Sample noise texture if available, otherwise use procedural noise
    float noise = 0.0;
    if (textureSize(noise_texture, 0).x > 0) {
        noise = texture(noise_texture, uv_scrolled).r;
    } else {
        // Simple procedural noise
        float t = TIME * pulse_speed;
        noise = sin(uv_scrolled.x * 10.0 + t) * sin(uv_scrolled.y * 10.0 + t) * 0.5 + 0.5;
    }
    
    // Mix fresnel effect with noise for edge glow
    float edge_glow = mix(fresnel, noise, 0.3) * edge_intensity;
    
    // Apply emission for the glow effect
    EMISSION = emission_color.rgb * emission_strength * (0.5 + edge_glow * 0.5);
    
    // Add some specularity and roughness
    METALLIC = 0.7;
    SPECULAR = 0.8;
    ROUGHNESS = 0.1;
}
