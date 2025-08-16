//A very simple "snow" shader to showcase environment texture shaders
shader_type spatial;

uniform sampler2D effect_texture;

//The vertex is moved up or down based on the value of the image
void vertex() {
	VERTEX.y -= texture(effect_texture, UV).r*0.3;
}

//we blend the colour based on the same value
void fragment() {
	ALBEDO = mix(vec3(1,1,1), vec3(0.4,0.2,0.2), texture(effect_texture, UV).r);
}


