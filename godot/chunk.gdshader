shader_type spatial;

uniform sampler2D ALBEDO_TEXTURE;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    // Get the base albedo color and texture
    vec4 albedo = texture(ALBEDO_TEXTURE, UV) * COLOR;

    // Apply checker pattern
	if (int(UV.x * 100.0) < 10){
		if ((int(UV.x * 100.0) / 10) % 2 == 0 && (int(UV.y * 100.0) / 10) % 2 == 0) {
			albedo.rgb *= 0.1;
		}
	}


    ALBEDO = albedo.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
