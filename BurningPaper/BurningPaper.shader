shader_type canvas_item;

uniform vec2 u_scale = vec2(1.); // 材质缩放
uniform sampler2D u_noise1;	// 噪声采样
uniform sampler2D u_noise2;
uniform float u_edge = .5;	// 边界
uniform float u_burn_width = .26;	// 燃烧区域
uniform float u_fire_width = .12;	// 火焰区域
uniform float u_ash_width = .16;	// 灰烬区域

void fragment() {
	vec2 uv = UV * u_scale;
//	float edge = u_edge * u_scale.y;
	float edge = (u_edge * u_scale.y) * (u_scale.y + u_burn_width + u_ash_width) - u_ash_width;
	// 噪声叠加
	vec2 noise_coord1 = uv + vec2(.0, 2.3) * TIME * .1;
	vec2 noise_coord2 = uv + vec2(.0, 1.) * TIME * .1;
	vec4 noise1 = texture(u_noise1, noise_coord1);
	vec4 noise2 = texture(u_noise2, noise_coord2);
	vec4 noise = (noise1 + noise2) * .5;
	
	// 燃烧区域
	float burn_mix = smoothstep(edge - u_burn_width, edge, uv.y);
	vec3 burn = noise.rgb;
	
	// 火焰区域
	float fire_offset = smoothstep(.2, 1., noise.r) * u_fire_width;
	float fire_mix = smoothstep(edge - u_fire_width, edge, uv.y + fire_offset) - 
	smoothstep(edge, edge + u_fire_width, uv.y - fire_offset);
	float n = noise.r;
	vec3 fire = vec3(2.*n, 1.5*n*n, n*n*n*n);	// 通过噪声计算火焰颜色
	fire *= 1.5;	// 加强
	burn = mix(burn, fire, fire_mix);	// 混合到燃烧区域

	// 灰烬区域
	float ash_mix = smoothstep(edge, edge + u_fire_width, uv.y - fire_offset);
	vec3 ash = vec3(.0);
	
	// 纸张扭曲
//	vec2 offset = vec2(noise1.r, noise2.r) - .5;
	vec2 offset = (1. - step(1., u_edge)) * (vec2(noise1.r, noise2.r) - .5);
	offset *= smoothstep(edge - u_burn_width, u_scale.y, uv.y) * .08;
	vec4 color = texture(TEXTURE, UV + offset);
	
	// 混合颜色
	color.rgb = mix(color.rgb, burn, burn_mix);
	color.rgb = mix(color.rgb, ash, ash_mix);
	color.a *= 1. - smoothstep(edge, edge + u_ash_width, uv.y - noise.r * u_ash_width);

	COLOR = color;
}