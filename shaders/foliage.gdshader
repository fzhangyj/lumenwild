shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.32,0.49,0.20,1.0);
varying vec3 world_pos;
varying float local_height;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7))) * 43758.5453); }
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 local_height = VERTEX.y + 0.5;
 VERTEX.x += sin(TIME*1.1+world_pos.x*0.19+world_pos.z*0.21)*0.009*local_height;
}
void fragment() {
 float leaf = hash(floor(world_pos*9.0));
 float patch = sin(world_pos.x*2.3 + sin(world_pos.z*3.2)) * sin(world_pos.y*3.4);
 ALBEDO = base_color.rgb * (0.84 + patch*0.10 + leaf*0.13 + local_height*0.19);
 ROUGHNESS = 0.9;
 SPECULAR = 0.18;
 BACKLIGHT = base_color.rgb * 0.16;
}
