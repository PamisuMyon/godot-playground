shader_type canvas_item;

uniform vec2 u_scale = vec2(1.0); // 材质缩放
uniform vec4 u_tint : hint_color; // 染色
uniform sampler2D u_noise1; // 噪声采样
uniform sampler2D u_noise2;
uniform float u_water_top = 0.2;  // 水上空气部分占材质比值
uniform float u_surface_height = 0.03; // 水面厚度
uniform vec4 u_surface_color : hint_color = vec4(vec3(1.0), 0.5); // 水面颜色
uniform vec2 u_entry_point = vec2(-1); // 入水点
uniform float u_enter_time = 0; // 入水时间

float wave(vec2 current, vec2 source, float time_passed) {
	if (source.y < 0.0)
		return 0.0;
	
	float len = length(current - source);
	float amplitude = 5.0 * sin(time_passed * 20.0 - len * 0.2);
	amplitude /= 1.0 + len * 0.1; // 按距离衰减
	amplitude *= exp(-time_passed); // 按时间衰减
	return amplitude;
}

void fragment() {
	// 缩放后的UV
	vec2 uv = UV * u_scale;
	// 取噪声颜色值为偏移量
	vec2 noise_coord1 = uv + TIME * vec2(1.0, 1.0) * 0.1;
	vec2 noise_coord2 = uv + TIME * vec2(-2.0, -2.0) * 0.1;
	vec4 noise_color1 = texture(u_noise1, noise_coord1);
	vec4 noise_color2 = texture(u_noise2, noise_coord2);
	vec2 offset = vec2(noise_color1.r, noise_color2.r) - 0.5;
	
	// 处理入水波动
	vec2 pixel_coord = uv / TEXTURE_PIXEL_SIZE;
	offset += wave(pixel_coord, u_entry_point, TIME - u_enter_time);
	offset *= 0.02;
	
	// 混合屏幕像素颜色
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV + offset, 0.0);
	color = mix(color, vec4(u_tint.rgb, 1.0), u_tint.a); // 染色
	color.rgb = mix(vec3(0.5), color.rgb, 1.2); // 增加对比度
	
	// 水面
	float current_y = uv.y + offset.y;
	float water_top = u_water_top * u_scale.y;
	vec4 surface_color = u_surface_color;
	surface_color.a *= smoothstep(water_top - u_surface_height, water_top, current_y)
		- smoothstep(water_top, water_top + u_surface_height, current_y);
	color = mix(color, vec4(surface_color.rgb, 1.0), surface_color.a);
	color.a = step(water_top - u_surface_height / 3.0, current_y);
	
	COLOR = color;
}