shader_type canvas_item;
render_mode unshaded;

uniform vec4 artwork_region;
uniform float frame_width = 1.0;
uniform float edge_inset = 0.0;
uniform float health_fill : hint_range(0.0, 1.0) = 1.0;
varying vec2 frame_position;

void vertex() {
	frame_position = VERTEX;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = UV * vec2(textureSize(TEXTURE, 0));
	vec2 art = (pixel - artwork_region.xy) / artwork_region.zw;
	// Replace the painted inset itself, including its curved ends. A rectangle
	// behind the frame cannot reach these corners without leaving black gaps.
	float plum = step(0.012, source.b - source.g) * step(0.006, source.r - source.g);
	plum *= 1.0 - step(0.45, max(source.r, source.b));
	float face = step(0.065, art.x) * step(art.x, 0.935);
	face *= step(0.26, art.y) * step(art.y, 0.88);
	float end = mix(edge_inset, frame_width - edge_inset, health_fill);
	float filled = step(frame_position.x, end) * step(0.0001, health_fill);
	filled = max(filled, step(0.9999, health_fill));
	float height = clamp((art.y - 0.26) / 0.62, 0.0, 1.0);
	float shine = smoothstep(0.0, 0.25, height) * (1.0 - smoothstep(0.35, 1.0, height));
	vec3 red = mix(vec3(0.22, 0.02, 0.045), vec3(0.65, 0.14, 0.21), shine);
	vec3 resource = mix(vec3(0.025, 0.015, 0.03), red, filled);
	COLOR = vec4(mix(source.rgb, resource, plum * face), source.a);
}
