shader_type spatial;
render_mode blend_mul;

varying vec4 vertex_color;

void vertex() {
	// Called for every vertex the material is visible on.
    vertex_color = COLOR;
}

void fragment() {
    // Called for every pixel the material is visible on.
    // vec4 color = texture(TEXTURE, UV);
    ALBEDO = vertex_color.rgb;
    ALPHA = vertex_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}