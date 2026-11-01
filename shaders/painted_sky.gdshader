shader_type sky;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void sky() {
 float elevation = max(EYEDIR.y,0.0);
 vec3 color = mix(vec3(0.68,0.83,0.88),vec3(0.16,0.43,0.69),pow(elevation,0.42));
 vec2 p = EYEDIR.xz / max(EYEDIR.y+0.16,0.08)*2.0;
 p.x += TIME*0.002;
 float cloud = noise(p)*0.57 + noise(p*2.03)*0.27 + noise(p*4.07)*0.12 + noise(p*8.1)*0.04;
 float mask = smoothstep(0.49,0.69,cloud) * smoothstep(0.025,0.16,elevation);
 vec3 cloud_color = mix(vec3(0.76,0.83,0.87),vec3(1.0,0.98,0.91),smoothstep(0.49,0.76,cloud));
 color = mix(color,cloud_color,mask*0.95);
 if (LIGHT0_ENABLED) {
  float sun = max(dot(EYEDIR,LIGHT0_DIRECTION),0.0);
  color += vec3(1.0,0.80,0.54)*pow(sun,24.0)*0.14;
  color += vec3(1.0,0.93,0.75)*smoothstep(0.9995,0.99985,sun)*0.7;
 }
 COLOR = color;
}
