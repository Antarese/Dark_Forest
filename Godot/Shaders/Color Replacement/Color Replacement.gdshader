shader_type canvas_item;


// color to replace (source color)
uniform vec4 target_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 replacement_color : source_color = vec4(94.0, 177.0, 191.0, 1.0);


void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	if (original_color == target_color) {
		COLOR = replacement_color;
	} else {
		COLOR = original_color;
	}
}