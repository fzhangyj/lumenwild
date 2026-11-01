shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.51, 0.64, 0.27, 1.0);
varying float tip;
void vertex() {
	tip = VERTEX.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(world.x * 0.6 + world.z * 0.5 + TIME * 1.6) * 0.12 * VERTEX.y;
}
void fragment() {
	ALBEDO = mix(tint.rgb * 0.72, tint.rgb * 1.17, tip);
	ROUGHNESS = 1.0;
}
