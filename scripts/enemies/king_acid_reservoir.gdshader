shader_type canvas_item;
uniform float acid_level : hint_range(0.0, 1.0) = 1.0;
varying vec4 sprite_tint;
void vertex() { sprite_tint = COLOR; }
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	bool liquid = sample_color.g > sample_color.r * 1.12 && sample_color.g > sample_color.b * 1.35;
	if (liquid && UV.y < 0.5) {
		float height = (UV.y - 0.04) / 0.44;
		float wet = smoothstep(1.0 - acid_level - 0.025, 1.0 - acid_level + 0.025, height);
		sample_color.rgb = mix(sample_color.rgb * vec3(0.20, 0.31, 0.29), sample_color.rgb, wet);
	}
	COLOR = sample_color * sprite_tint;
}
