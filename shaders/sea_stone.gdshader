shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 stone_color: source_color = vec4(0.4,0.6,0.6,1.0);
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 p=world_position.xz;
	float grain=sin(p.x*1.7+sin(p.y*2.3))*sin(p.y*1.9+p.x*0.6);
	float veins=pow(1.0-abs(sin(p.x*0.55+sin(p.y*0.74)+TIME*0.25)),12.0);
	veins*=pow(1.0-abs(sin(p.y*0.40+cos(p.x*0.62)-TIME*0.19)),3.0);
	float joints=step(0.94,fract(p.x*0.25))+step(0.96,fract(p.y*0.25));
	ALBEDO=stone_color.rgb*(0.95+grain*0.085-joints*0.10)+vec3(0.32,0.65,0.58)*veins*0.35;
	EMISSION=vec3(0.12,0.40,0.33)*veins*0.28;
	ROUGHNESS=0.72;
}
