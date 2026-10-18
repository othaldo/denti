shader_type canvas_item;
render_mode unshaded;

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float trail : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;
uniform float impact : hint_range(0.0, 1.0) = 0.0;
uniform float motion : hint_range(0.0, 1.0) = 1.0;
uniform vec2 cavity_y = vec2(0.09, 0.91);
uniform bool frame_pass = false;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	// The generated frame supplies a green replacement mask and its own alpha.
	float cavity = step(0.025, source.g - max(source.r, source.b));
	float amplitude = 0.006 * motion * sin(fill * 3.14159);
	float wave = amplitude * (sin(UV.x * 19.0 + phase * 2.0) + 0.45 * sin(UV.x * 31.0 - phase * 1.3));
	float level = mix(cavity_y.y, cavity_y.x, fill) + wave;
	float trail_level = mix(cavity_y.y, cavity_y.x, trail);
	float wet = smoothstep(level - 0.003, level + 0.003, UV.y) * step(0.0001, fill);
	float lost = smoothstep(trail_level - 0.003, trail_level + 0.003, UV.y) * step(0.0001, trail);
	vec3 empty_color = mix(vec3(0.07, 0.04, 0.10), vec3(0.16, 0.10, 0.20), 1.0 - UV.y);
	vec3 liquid = mix(vec3(0.48, 0.065, 0.13), vec3(1.0, 0.37, 0.40), clamp((1.0 - UV.y) * 1.1, 0.0, 1.0));
	liquid += vec3(0.18, 0.055, 0.04) * (0.5 + 0.5 * sin(UV.x * 8.0 + UV.y * 12.0 + phase * 0.7)) * motion;
	float surface = (1.0 - smoothstep(0.0, 0.018, abs(UV.y - level))) * wet;
	liquid += surface * vec3(0.48, 0.28, 0.17);
	// Four small, independently drifting bubbles; no spawned nodes or particles.
	for (int i = 0; i < 4; i++) {
		float n = float(i);
		vec2 bubble = vec2(0.27 + n * 0.15 + sin(phase * 0.6 + n * 2.1) * 0.018, 0.90 - fract(phase * (0.035 + n * 0.009) + n * 0.237) * 0.78);
		float distance_to_bubble = length((UV - bubble) * vec2(1.0, 1.1));
		float ring = 1.0 - smoothstep(0.002, 0.005, abs(distance_to_bubble - 0.012));
		liquid += ring * vec3(0.30, 0.16, 0.13) * motion;
	}
	vec3 interior = mix(empty_color, vec3(0.75, 0.39, 0.25), lost * 0.55);
	interior = mix(interior, liquid + impact * vec3(0.25, 0.12, 0.08), wet);
	// A faint glass reflection makes the empty half feel like a vessel too.
	interior += exp(-pow((UV.x - 0.30) * 30.0, 2.0)) * 0.045;
	// The liquid polygon follows the outer contour, so holes in generated alpha
	// never become holes in the resource. The separate painted frame sits above it.
	COLOR = frame_pass ? vec4(source.rgb, source.a * (1.0 - cavity)) : vec4(interior, 1.0);
}
