shader_type spatial;

uniform sampler2D effect_texture;

void fragment() {
	//ALBEDO = vec3(UV.y);
	ALBEDO = mix(vec3(1.0,0.3,0.3), vec3(0.0,0.0,0.0), texture(effect_texture, UV).r);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
