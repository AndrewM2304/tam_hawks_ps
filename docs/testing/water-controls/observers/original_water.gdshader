shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world_position.xz;
	float phase_a=dot(p,vec2(0.085,0.031))+TIME*0.31;
	float phase_b=dot(p,vec2(-0.028,0.13))-TIME*0.46;
	float phase_c=dot(p,vec2(0.21,-0.17))+TIME*0.22;
	float wave=0.58*sin(phase_a)+0.32*sin(phase_b)+0.10*sin(phase_c);
	float tone=clamp(0.5+0.5*wave,0.0,1.0);
	ALBEDO=mix(vec3(0.075,0.17,0.19),vec3(0.13,0.245,0.26),tone);
	ROUGHNESS=mix(0.62,0.76,tone);
	METALLIC=0.0;
	SPECULAR=0.10;
	vec2 slope=0.52*cos(phase_a)*vec2(0.085,0.031)
		+0.29*cos(phase_b)*vec2(-0.028,0.13)
		+0.10*cos(phase_c)*vec2(0.21,-0.17);
	vec3 tangent_normal=normalize(vec3(-slope.x*2.2,-slope.y*2.2,1.0));
	NORMAL_MAP=tangent_normal*0.5+0.5;
	NORMAL_MAP_DEPTH=0.55;
}
