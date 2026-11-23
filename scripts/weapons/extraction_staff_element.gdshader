shader_type canvas_item;

uniform vec4 element_color : source_color = vec4(1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Limit the recoloring to the jade crystal between the forceps.
	float head = smoothstep(0.792, 0.808, UV.x) * (1.0 - smoothstep(0.937, 0.952, UV.x));
	head *= smoothstep(0.040, 0.054, UV.y) * (1.0 - smoothstep(0.175, 0.190, UV.y));
	float jade = smoothstep(0.018, 0.13, pixel.g - pixel.r);
	jade *= smoothstep(-0.045, 0.035, pixel.g - pixel.b);
	float bright = smoothstep(0.06, 0.88, pixel.g);
	float highlight = smoothstep(0.50, 0.99, min(pixel.r, min(pixel.g, pixel.b)));
	vec3 gem = mix(element_color.rgb * 0.24, element_color.rgb, bright);
	gem = mix(gem, vec3(1.0), highlight * 0.88);
	COLOR = vec4(mix(pixel.rgb, gem, head * jade), pixel.a) * vertex_tint;
}
