shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float motion : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D distance_field : filter_linear, repeat_disable;
uniform float tooth_size = 108.0;
uniform int charges = 0;

void fragment() {
	vec2 packed = texture(distance_field, UV).rg;
	float encoded = (packed.r * 256.0 + packed.g) / 257.0;
	float distance = (encoded - 0.5) * 0.5 * tooth_size;
	float aa = max(fwidth(distance), 0.3);
	vec2 p = UV * 1.5 - 0.25;
	float angle = atan(p.y - 0.5, p.x - 0.5);
	float core = 0.0;
	float glow = 0.0;
	float highlight = 0.0;
	for (int i = 0; i < 5; i++) {
		if (i >= charges) { break; }
		float separation = abs(distance - (2.0 + float(i) * 3.2));
		float line = 1.0 - smoothstep(0.6 - aa * 0.5, 0.6 + aa * 0.5, separation);
		float light = pow(0.5 + 0.5 * cos(angle - phase * 1.2 + float(i) * 0.35), 12.0) * motion;
		core = max(core, line);
		glow += exp(-separation * separation / (2.0 * 1.7 * 1.7)) * 0.13;
		highlight = max(highlight, light * line);
	}
	float sweep = pow(max(0.0, cos((p.x + p.y * 0.65) * 7.0 - phase * 1.2)), 14.0);
	float inside = 1.0 - smoothstep(-aa, aa, distance);
	float glass = inside * (0.065 + sweep * 0.07 * motion);
	float opacity = max(glass, min(0.92, core * 0.86 + glow));
	vec3 color = mix(vec3(0.12, 0.48, 0.85), vec3(0.31, 0.82, 1.0), core);
	color = mix(color, vec3(0.86, 0.98, 1.0), highlight * 0.8);
	// A finite tail keeps the layout's glow padding accurate.
	COLOR = vec4(color, opacity < 0.003 ? 0.0 : opacity);
}
