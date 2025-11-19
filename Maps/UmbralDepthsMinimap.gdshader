shader_type canvas_item;

uniform sampler2D fog_map;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 fog = texture(fog_map, UV);
	COLOR = mix(vec4(0.0,0.0,0.0,1.0), base_color, fog.r);
}
