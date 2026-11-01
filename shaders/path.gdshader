shader_type spatial;
render_mode blend_mix, depth_draw_opaque;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float grain = hash(floor(world_pos.xz*22.0));
 float patches = sin(world_pos.x*1.4+sin(world_pos.z*1.7))*0.035;
 ALBEDO = vec3(0.47,0.42,0.29) + grain*0.045 + patches;
 ROUGHNESS = 1.0;
 SPECULAR = 0.06;
 float edge = min(UV.x,1.0-UV.x);
 ALPHA = smoothstep(0.0,0.10+grain*0.04,edge);
}
