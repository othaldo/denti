shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// HTML-inspired art study. Timing and visual fill are independent, explicit clocks.
uniform float path_length = 640.0;
uniform float half_width = 48.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float fill_progress : hint_range(0.0, 1.0) = 0.0;
uniform float clock_seconds = 0.0;
uniform float release_flash : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float source_fade : hint_range(0.0, 1.0) = 0.55;
uniform float line_width = 3.0;
uniform float glow_width = 9.0;
uniform float front_width = 48.0;
uniform bool cinematic = false;
uniform float release_seconds = -1.0;
uniform float charge_seconds = 0.65;
uniform vec4 body_color : source_color = vec4(1.0, 0.60, 0.22, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.94, 0.85, 1.0);
varying vec2 local_position;

void vertex() { local_position = VERTEX; }

float chamfer_box(vec2 point, vec2 extent, float cut) {
	vec2 q = abs(point) - extent;
	return max(max(q.x, q.y), (q.x + q.y + cut) * 0.70710678);
}

void over(inout vec4 result, vec3 color, float alpha) {
	alpha = clamp(alpha, 0.0, 1.0);
	result.rgb = color * alpha + result.rgb * (1.0 - alpha);
	result.a = alpha + result.a * (1.0 - alpha);
}

void fragment() {
	if (opacity < 0.001) { discard; }
	vec2 p = local_position;
	float d = chamfer_box(p - vec2(path_length * 0.5, 0.0), vec2(path_length * 0.5, half_width), min(12.0, half_width * 0.25));
	// Derivatives follow the actual viewport, camera zoom and rotated geometry.
	float aa = max(length(vec2(dFdx(d), dFdy(d))), 0.001);
	float pixel_x = max(length(vec2(dFdx(p.x), dFdy(p.x))), 0.001);
	float inside = 1.0 - smoothstep(-aa, aa, d);
	float edge = abs(d);
	float front = path_length * fill_progress;
	float filled = (1.0 - smoothstep(front - pixel_x, front + pixel_x, p.x)) * step(0.001, fill_progress);
	float band = clamp(1.0 - (front - p.x) / front_width, 0.0, 1.0) * filled;
	float face = (1.0 - smoothstep(1.0, 1.8 + pixel_x, abs(p.x - front))) * step(0.001, fill_progress) * (1.0 - step(0.999, fill_progress));
	// Urgency follows real warning time, independently of the eased fill distance.
	float urgency = smoothstep(0.75, 1.0, progress);
	float pulse = (0.5 + 0.5 * sin(clock_seconds * 12.0 + urgency * urgency * 12.0)) * urgency;
	float halo = exp(-pow(edge / (glow_width * (1.0 + pulse * 0.45 + release_flash * 0.5)), 2.0));
	float rim = 1.0 - smoothstep(line_width * 0.5, line_width * 0.5 + aa, edge);
	float core = 1.0 - smoothstep(0.45, 0.7 + aa, edge);
	// Clear travelling chevrons, restricted to the already filled part of the lane.
	float chevron_height = half_width * 0.56;
	float chevron_x = p.x + abs(p.y) / chevron_height * 26.0 - clock_seconds * 70.0;
	float repeat_distance = abs(mod(chevron_x + 35.0, 70.0) - 35.0);
	float arrow_aa = max(fwidth(chevron_x), 0.001);
	float arrow = (1.0 - smoothstep(1.25, 1.25 + arrow_aa, repeat_distance)) * (1.0 - smoothstep(chevron_height - aa, chevron_height + aa, abs(p.y))) * filled;
	vec4 result = vec4(0.0);
	if (!cinematic) {
		over(result, body_color.rgb, halo * (0.24 + pulse * 0.10));
		over(result, body_color.rgb, inside * (0.06 + filled * 0.22));
		over(result, core_color.rgb, inside * band * 0.30);
		over(result, core_color.rgb, inside * arrow * 0.32);
		over(result, core_color.rgb, inside * face * 0.90);
		over(result, body_color.rgb, rim * 0.94);
		over(result, core_color.rgb, core * (0.64 + pulse * 0.28));
		over(result, core_color.rgb, release_flash * inside * 0.35);
	}
	// Fade softly towards the caster, matching the supplied test bank.
	float source = 1.0;
	if (source_fade > 0.001) {
		float fraction = clamp((p.x + 10.0) / (path_length * source_fade + 10.0), 0.0, 1.0);
		source = fraction < 0.55 ? fraction * (0.35 / 0.55) : 0.35 + (fraction - 0.55) * (0.65 / 0.45);
	}
	if (cinematic) {
		// Stable danger boundary; energy/brightness have their own, later envelopes.
		float tension = smoothstep(0.18, 1.0, progress);
		float brilliance = smoothstep(0.62, 1.0, progress);
		float advance = clock_seconds * 70.0 + progress * progress * 140.0;
		float flow_y = sin(p.x * 0.013 - advance * 0.025) * half_width * 0.32;
		float flow_distance = abs(p.y - flow_y);
		float flow_aa = max(fwidth(p.y - flow_y), 0.001);
		float filament = 1.0 - smoothstep(0.6, 0.6 + flow_aa, flow_distance);
		float ribbon = exp(-flow_distance * flow_distance / 100.0);
		float energy = inside * filled * source * tension;
		result = vec4(0.0);
		over(result, body_color.rgb, halo * (0.15 + brilliance * 0.12));
		over(result, body_color.rgb, inside * (0.035 + filled * 0.11) * source);
		over(result, body_color.rgb, energy * ribbon * 0.26);
		over(result, core_color.rgb, energy * filament * 0.27);
		over(result, core_color.rgb, inside * band * source * (0.18 + brilliance * 0.20));
		over(result, core_color.rgb, inside * arrow * source * 0.16);
		over(result, core_color.rgb, inside * face * max(source, 0.28) * (0.70 + brilliance * 0.25));
		// A restrained floor sheen, strongest where energy concentrates.
		float sheen = exp(-pow((p.x - front + 18.0) / 40.0, 2.0) - pow(p.y / (half_width * 1.5), 2.0));
		over(result, body_color.rgb, sheen * tension * 0.12);
		over(result, body_color.rgb, rim * (0.38 + brilliance * 0.20) * max(source, 0.32));
		over(result, core_color.rgb, core * (0.48 + brilliance * 0.24) * max(source, 0.32));
		if (release_seconds >= 0.0) {
			// The warning disappears on release; the moving wake owns the light now.
			result *= 1.0 - smoothstep(0.0, 0.12, release_seconds);
			float head = min(release_seconds / charge_seconds, 1.0) * path_length;
			float tail_length = min(head + 20.0, 175.0);
			float along = clamp((p.x - head + tail_length) / max(tail_length, 1.0), 0.0, 1.0);
			float wake = smoothstep(0.0, 1.0, along) * (1.0 - smoothstep(head, head + 16.0, p.x));
			float dissolve = 1.0 - smoothstep(charge_seconds - 0.08, charge_seconds + 0.28, release_seconds);
			float width = 6.0 + (1.0 - along) * 18.0;
			float trail = exp(-pow((p.y - flow_y * 0.15) / width, 2.0)) * wake * dissolve;
			over(result, body_color.rgb, trail * 0.52);
			over(result, core_color.rgb, trail * along * 0.50);
			float flare = exp(-pow(p.x / 28.0, 2.0) - pow(p.y / 22.0, 2.0));
			over(result, core_color.rgb, flare * release_flash * 0.65);
		}
		COLOR = result * opacity;
	} else {
		COLOR = result * opacity * source;
	}
}
