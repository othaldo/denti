shader_type canvas_item;

uniform vec2 frame_cell;
uniform vec2 frame_grid = vec2(1.0);
uniform vec2 root_lift;
uniform vec2 root_swing;
uniform float root_split = 0.5;
uniform float root_start = 0.70;
varying vec4 body_color;

void vertex() {
	body_color = COLOR;
}

void fragment() {
	vec2 local_uv = UV * frame_grid - frame_cell;
	float roots = smoothstep(root_start, 0.90, local_uv.y);
	float right = smoothstep(root_split - 0.06, root_split + 0.06, local_uv.x);
	vec2 motion = vec2(mix(root_swing.x, root_swing.y, right), -mix(root_lift.x, root_lift.y, right));
	vec2 half_texel = TEXTURE_PIXEL_SIZE * frame_grid * 0.5;
	vec2 sample_uv = clamp(local_uv - motion * roots, half_texel, vec2(1.0) - half_texel);
	COLOR = texture(TEXTURE, (sample_uv + frame_cell) / frame_grid) * body_color;
}
