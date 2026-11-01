shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled;
uniform float width = 0.004;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = vec3(0.075, 0.085, 0.13);
}
