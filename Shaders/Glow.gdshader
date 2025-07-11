shader_type canvas_item;

uniform vec3 glow_color: source_color = vec3(0.2, 0.6, 0.3);
uniform float glow_power: hint_range(0.0, 0.0, 0.1) = 2.0;

void fragment() {
	COLOR = texture(TEXTURE, UV) * vec4(glow_color, 1.0) * glow_power;
}