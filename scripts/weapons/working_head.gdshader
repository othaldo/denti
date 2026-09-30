shader_type canvas_item;
uniform vec2 region_start = vec2(0.0);
uniform vec2 region_extent = vec2(1.0);

void fragment() {
	vec2 local_uv = (UV - region_start) / region_extent;
	float distance_to_center = length(local_uv - vec2(0.5));
	float edge = max(fwidth(distance_to_center), 0.002);
	COLOR.a *= 1.0 - smoothstep(0.5 - edge, 0.5, distance_to_center);
}
