shader_type spatial;
render_mode diffuse_burley;
uniform bool stone = false;
varying vec3 world_pos;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 float broad = noise(world_pos.xz * 0.075);
 float fleck = noise(world_pos.xz * 2.5) * 0.055 + noise(world_pos.xz * 15.0) * 0.018;
 vec3 meadow = mix(vec3(0.22,0.36,0.135), vec3(0.43,0.52,0.235), broad);
 float trail = 1.0 - smoothstep(3.0, 4.3, abs(world_pos.x));
 meadow = mix(meadow, vec3(0.45,0.47,0.28), trail * 0.15);
 vec3 rock_color = mix(vec3(0.34,0.39,0.38),vec3(0.57,0.57,0.48),noise(world_pos.xz*0.42+world_pos.y*0.7));
 float slope = 1.0 - smoothstep(0.72,0.95,world_normal.y);
 vec3 terrain = mix(meadow, rock_color, slope * 0.85);
 terrain = mix(terrain, vec3(0.64,0.60,0.43),1.0-smoothstep(-0.5,1.4,world_pos.y));
 ALBEDO = (stone ? rock_color : terrain) + fleck;
 ROUGHNESS = 0.94;
 SPECULAR = 0.14;
}
