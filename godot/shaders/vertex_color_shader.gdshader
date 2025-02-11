shader_type spatial;
render_mode blend_mul;

varying vec4 vertex_color;

void vertex() {
    vertex_color = COLOR;
}

void fragment() {
    // vec4 color = texture(TEXTURE, UV);
    ALBEDO = vertex_color.rgb;
    ALPHA = vertex_color.a;
}