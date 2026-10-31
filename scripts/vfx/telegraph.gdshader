shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform bool edge_pass = false;
varying flat vec4 data;
varying vec4 tint;

void vertex() {
	data = INSTANCE_CUSTOM;
	tint = COLOR;
}

float segment_distance(vec2 p, vec2 end) {
	return length(p - end * clamp(dot(p, end) / max(dot(end, end), 0.0001), 0.0, 1.0));
}

void over(inout vec4 result, vec3 color, float alpha) {
	alpha = clamp(alpha, 0.0, 1.0);
	result.rgb = color * alpha + result.rgb * (1.0 - alpha);
	result.a = alpha + result.a * (1.0 - alpha);
}

void fragment() {
	int encoded = int(floor(data.x));
	int shape = encoded % 8;
	int phase = encoded / 8;
	float limit = fract(data.x) * 2.0;
	float time = clamp(data.y, 0.0, 1.0);
	float first = data.z;
	float second = data.w;
	float fill_progress = phase == 0 ? pow(time, 2.2) * limit : 1.0;
	vec2 extent = vec2(first + 14.0);
	if (shape == 0 || shape == 3) extent = vec2(first * 0.5 + 14.0 + (shape == 3 ? second : 0.0), second + 14.0);
	float sector_left = first * min(cos(second), 0.0);
	if (shape == 2) extent = vec2((first - sector_left) * 0.5 + 14.0, first * sin(min(second, PI * 0.5)) + 14.0);
	vec2 p = (UV * 2.0 - 1.0) * extent;
	// QuadMesh UVs run opposite to canvas Y. Keep timers top-start/clockwise.
	p.y = -p.y;
	if (shape == 2) p.x += (first + sector_left) * 0.5;
	float d;
	float along;
	float span;
	float lateral = p.y;
	float source;
	if (shape == 0 || shape == 3) {
		p.x += first * 0.5;
		if (shape == 3) {
			d = length(p - vec2(clamp(p.x, 0.0, first), 0.0)) - second;
			along = p.x + second;
			span = first + second * 2.0;
		} else {
			vec2 q = abs(p - vec2(first * 0.5, 0.0)) - vec2(first * 0.5, second);
			d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
			along = p.x;
			span = first;
		}
		source = smoothstep(0.0, span * 0.45, along);
	} else {
		float radius = length(p);
		float angle = abs(atan(p.y, p.x));
		along = radius;
		span = first;
		d = radius - first;
		if (shape == 1) {
			if (second > 0.0) d = max(d, second - radius);
			along -= second;
			span -= second;
		} else if (shape == 2 && second < PI - 0.001) {
			vec2 endpoint = vec2(cos(second), sin(second)) * first;
			vec2 folded = vec2(p.x, abs(p.y));
			float outer_edge = angle <= second ? abs(radius - first) : length(folded - endpoint);
			float edge = min(outer_edge, segment_distance(folded, endpoint));
			d = edge * (angle <= second && radius <= first ? -1.0 : 1.0);
		}
		source = smoothstep(0.0, span * 0.45, along);
		lateral = sin(atan(p.y, p.x) * 5.0) * 18.0;
	}
	float aa = max(length(vec2(dFdx(d), dFdy(d))), 0.001);
	float along_aa = max(fwidth(along), 0.001);
	float inside = 1.0 - smoothstep(-aa * 0.5, aa * 0.5, d);
	float front = span * fill_progress;
	float filled = (1.0 - smoothstep(front - along_aa, front + along_aa, along)) * step(0.001, fill_progress);
	float front_distance = abs(along - front);
	float front_core = 1.0 - smoothstep(0.9, 0.9 + along_aa, front_distance);
	float band = clamp(1.0 - (front - along) / 35.0, 0.0, 1.0) * filled;
	float brilliance = smoothstep(0.62, 1.0, time);
	float energy_clock = time * 6.0 + time * time * 5.0;
	float wave_distance = abs(mod(along + lateral * 0.20 - energy_clock * 25.0 + 36.0, 72.0) - 36.0);
	float wave_aa = max(fwidth(along + lateral * 0.20), 0.001);
	float waves = 1.0 - smoothstep(0.65, 0.65 + wave_aa, wave_distance);
	vec3 warm = tint.rgb;
	vec3 hot = mix(warm, vec3(1.0), 0.78);
	vec4 result = vec4(0.0);
	if (shape == 4) {
		// Source timers are arcs, not a fictitious circular damage area.
		float angle = mod(atan(p.y, p.x) + PI * 0.5 + TAU, TAU);
		float end = time * TAU;
		d = abs(length(p) - first);
		if (time < 0.9999 && angle > end) d = min(length(p - vec2(0.0, -first)), length(p - vec2(sin(end), -cos(end)) * first));
		float timer_aa = max(fwidth(d), 0.001);
		if (edge_pass && time > 0.001) {
			over(result, warm, exp(-d * d / 16.0) * 0.20);
			over(result, warm, (1.0 - smoothstep(1.4, 1.4 + timer_aa, d)) * 0.85);
			over(result, hot, (1.0 - smoothstep(0.45, 0.45 + timer_aa, d)) * 0.75);
		}
	} else if (edge_pass) {
		float edge = abs(d);
		over(result, warm, exp(-edge * edge / 36.0) * (0.16 + brilliance * 0.08));
		over(result, warm, (1.0 - smoothstep(1.3, 1.3 + aa, edge)) * 0.83);
		over(result, hot, (1.0 - smoothstep(0.45, 0.45 + aa, edge)) * (0.50 + brilliance * 0.22));
		if (phase == 0) over(result, hot, inside * front_core * max(source, 0.28) * (0.55 + brilliance * 0.3) * step(0.001, fill_progress) * (1.0 - step(0.999, fill_progress)));
	} else {
		over(result, warm, inside * (0.045 + filled * (phase == 0 ? 0.13 : 0.18)));
		over(result, hot, inside * band * source * (0.13 + brilliance * 0.15));
		over(result, hot, inside * filled * waves * source * 0.17);
		if (phase == 1) over(result, hot, inside * 0.10);
	}
	COLOR = result * tint.a;
}
