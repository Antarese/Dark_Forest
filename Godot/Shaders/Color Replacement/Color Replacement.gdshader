shader_type canvas_item;

// color to replace (source color)
uniform vec4 target_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Color to replace target_color with
const vec4 replacement_color = vec4(1.0, 0.0, 0.0, 1.0);
const vec4 replacement_color_2 = vec4(1.0, 1.0, 1.0, 1.0);


void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	if (original_color.a == 0.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (original_color == target_color) {
		COLOR = replacement_color;
	} else {
		COLOR = replacement_color_2;
	}
}
