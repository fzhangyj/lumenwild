shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.19, 0.64, 0.68, 1.0);
uniform vec4 deep_color : source_color = vec4(0.10, 0.38, 0.52, 1.0);
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 0.14 + TIME * 0.6) * 0.13 + cos(world_pos.z * 0.18 + TIME * 0.48) * 0.1;
}

void fragment() {
	float waves = sin(world_pos.x * 0.72 + world_pos.z * 0.43 + TIME * 0.9) * sin(world_pos.z * 0.8 - TIME * 0.5);
	float glint = pow(max(waves, 0.0), 18.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, 0.5 + waves * 0.18) + glint * 0.23;
	ROUGHNESS = 0.3;
	METALLIC = 0.15;
}
