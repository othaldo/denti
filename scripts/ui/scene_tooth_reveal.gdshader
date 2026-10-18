shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tooth_distance : filter_linear, repeat_disable;
uniform sampler2D incoming_screen : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float easing = smoothstep(0.0, 0.8, progress);
	float old_zoom = 1.0 + 0.055 * easing;
	float new_zoom = 1.0 + 0.075 * (1.0 - smoothstep(0.2, 1.0, progress));
	vec4 previous = texture(TEXTURE, (UV - vec2(0.5)) / old_zoom + vec2(0.5));
	vec4 incoming = texture(incoming_screen, (SCREEN_UV - vec2(0.5)) / new_zoom + vec2(0.5));
	if (progress <= 0.001) {
		COLOR = previous;
	} else {
		// Uniform pixel-space scaling keeps the tooth intact in every aspect.
		float scale = max(1.0, max(viewport_size.x, viewport_size.y) * 3.6 * progress * progress);
		vec2 tooth_point = (UV - vec2(0.5)) * viewport_size / scale + vec2(0.5, 0.43);
		vec2 field_uv = (tooth_point + vec2(0.25)) / 1.5;
		vec2 packed = texture(tooth_distance, clamp(field_uv, vec2(0.0), vec2(1.0))).rg;
		float distance = ((packed.r * 256.0 + packed.g) / 257.0 - 0.5) * 0.5 * scale;
		float aa = max(fwidth(distance), 0.75);
		float bounds = step(0.0, field_uv.x) * step(field_uv.x, 1.0) * step(0.0, field_uv.y) * step(field_uv.y, 1.0);
		distance = mix(10000.0, distance, bounds);
		float weight = clamp(min(viewport_size.x, viewport_size.y) / 720.0, 0.75, 1.3);
		float rim_width = 7.0 * weight;
		float outside = smoothstep(-aa, aa, distance);
		float rim = 1.0 - smoothstep(rim_width - aa, rim_width + aa, abs(distance));
		float glow = exp(-abs(distance) / (16.0 * weight)) * 0.38;
		float bevel = max(0.0, 1.0 - abs(distance) / rim_width);
		float sweep = 1.0 - smoothstep(0.0, 0.17, abs(UV.x + UV.y * 0.6 - (progress * 2.2 - 0.3)));
		vec3 gold = mix(vec3(0.43, 0.22, 0.06), vec3(1.0, 0.75, 0.25), sqrt(bevel));
		gold = mix(gold, vec3(1.0, 0.98, 0.82), sweep * bevel * 0.95);
		// Darken the outgoing scene gently; the new scene opens at full colour.
		vec3 old_colour = mix(previous.rgb, vec3(0.10, 0.07, 0.13), smoothstep(0.0, 0.25, progress) * 0.48);
		float alpha = outside * previous.a;
		vec3 premultiplied = old_colour * alpha;
		premultiplied = gold * glow + premultiplied * (1.0 - glow);
		alpha = glow + alpha * (1.0 - glow);
		premultiplied = gold * rim + premultiplied * (1.0 - rim);
		alpha = rim + alpha * (1.0 - rim);
		// Sample the live incoming screen on the GPU so combat stays live and
		// the final settled frame matches exactly when this layer disappears.
		COLOR = vec4(premultiplied + incoming.rgb * (1.0 - alpha), 1.0);
	}
}
