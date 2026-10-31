shader_type canvas_item;

// Preserve the atlas batching and existing tint/transform contract.
varying vec4 ink;
void vertex() { ink = COLOR; }

float bell(float d, float width) { return exp(-d * d / (width * width)); }

void fragment() {
	// COLOR already includes the sampled texture; unrelated textures/atlas cells
	// must remain byte-for-byte on the ordinary rendering path.
	vec4 result = COLOR;
	bool atlas = abs(TEXTURE_PIXEL_SIZE.x - 1.0 / 2048.0) < 0.0000001 && abs(TEXTURE_PIXEL_SIZE.y - 1.0 / 1792.0) < 0.0000001;
	vec2 texel = UV * vec2(2048.0, 1792.0);
	if (atlas && texel.x < 960.0 && texel.y >= 1152.0 && texel.y < 1632.0) {
		vec2 cell = floor((texel - vec2(0.0, 1152.0)) / 80.0);
		float phase = cell.y * 12.0 + cell.x;
		if (phase >= 0.0 && phase <= 64.0) {
			vec2 p = texel - vec2(0.0, 1152.0) - cell * 80.0 - 40.0;
			float radius = length(p);
			float angle = mod(atan(p.y, p.x) + PI * 0.5 + TAU, TAU);
			float end = phase / 64.0 * TAU;
			float d = abs(radius - 32.0);
			// Smooth endpoints without a discontinuity at the arc's angular seam.
			if (phase < 64.0 && angle > end) {
				vec2 tip = vec2(sin(end), -cos(end)) * 32.0;
				d = min(length(p - vec2(0.0, -32.0)), length(p - tip));
			}
			float aa = max(length(vec2(dFdx(radius), dFdy(radius))), 0.001);
			float core = bell(d, sqrt(0.64 + aa * aa * 0.12));
			float glow = bell(d, sqrt(2.89 + aa * aa * 0.12));
			float alpha = min(1.0, core * 0.9 + glow * 0.45) * step(0.5, phase);
			result = ink * vec4(vec3(0.25 + core * 0.75), alpha);
		}
	} else if (atlas && texel.y >= 1728.0 && texel.y < 1792.0 && texel.x >= 1024.0 && texel.x < 1216.0) {
		float tile = floor((texel.x - 1024.0) / 64.0);
		vec2 p = (texel - vec2(1024.0 + tile * 64.0, 1728.0)) / 64.0;
		float v = abs(p.y * 2.0 - 1.0);
		float feather = 1.0 - smoothstep(0.68, 0.98, v);
		float body = (0.15 + 0.19 * bell(v, 0.42)) * feather;
		float alpha = body;
		if (tile < 1.5 && tile > 0.5) alpha *= smoothstep(0.0, 0.95, p.x);
		if (tile > 1.5) {
			float nose = 0.92 - v * v * 0.42;
			float distance_to_front = p.x - nose;
			float aa = fwidth(distance_to_front);
			float core = bell(distance_to_front, sqrt(0.003025 + aa * aa * 0.12));
			float glow = bell(distance_to_front, 0.19);
			alpha = min(1.0, body * (1.0 - smoothstep(nose - 0.08, nose + 0.04, p.x)) + (core * 0.75 + glow * 0.28) * feather);
		}
		result = ink * vec4(vec3(1.0), alpha);
	}
	COLOR = result;
}
