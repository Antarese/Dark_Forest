shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	float brightness_multiplier = 1.0 - darkness;
	vec3 darkened_rgb = original_color.rgb * brightness_multiplier;
	COLOR = vec4(darkened_rgb, original_color.a);
}