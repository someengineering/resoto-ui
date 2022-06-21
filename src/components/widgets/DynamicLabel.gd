tool
class_name DynamicLabel
extends Label

export (int) var min_font_size := 10
export (int) var max_font_size := 64

export (float) var base_width_ratio := 0.9

onready var font : DynamicFont = get("custom_fonts/font")

func _on_DynamicLabel_resized():
	if is_instance_valid(font):
		var size : Vector2
		var string_size := font.get_string_size(text)
		size = font.size * base_width_ratio * rect_size / string_size
		if abs(min(size.x, size.y) - font.size) > 1:
			font.size = int(clamp(min(size.x, size.y), min_font_size, max_font_size))

func get_text_size(_text := ""):
	if _text == "":
		_text = text
	return font.get_string_size(_text)
