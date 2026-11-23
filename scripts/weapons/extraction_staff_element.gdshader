shader_type canvas_item;

uniform vec4 element_color : source_color = vec4(1.0);
// Recolored region in UV (x0, y0, x1, y1); defaults: the extraction staff crystal.
uniform vec4 head_rect = vec4(0.8, 0.047, 0.945, 0.183);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Limit the recoloring to the jade crystal / seed in the staff head.
	float head = smoothstep(head_rect.x - 0.008, head_rect.x + 0.008, UV.x) * (1.0 - smoothstep(head_rect.z - 0.008, head_rect.z + 0.008, UV.x));
	head *= smoothstep(head_rect.y - 0.007, head_rect.y + 0.007, UV.y) * (1.0 - smoothstep(head_rect.w - 0.007, head_rect.w + 0.007, UV.y));
	float jade = smoothstep(0.018, 0.13, pixel.g - pixel.r);
	jade *= smoothstep(-0.045, 0.035, pixel.g - pixel.b);
	float bright = smoothstep(0.06, 0.88, pixel.g);
	float highlight = smoothstep(0.50, 0.99, min(pixel.r, min(pixel.g, pixel.b)));
	vec3 gem = mix(element_color.rgb * 0.24, element_color.rgb, bright);
	gem = mix(gem, vec3(1.0), highlight * 0.88);
	COLOR = vec4(mix(pixel.rgb, gem, head * jade), pixel.a) * vertex_tint;
}
