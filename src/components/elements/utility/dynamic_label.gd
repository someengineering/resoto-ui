tool
class_name DynamicLabel
extends Label

export (int) var min_font_size := 10
export (int) var max_font_size := 64

export (float) var base_width_ratio := 0.9

onready var font : DynamicFont = get("custom_fonts/font")

var resizeing := false
var prev_size := Vector2.ZERO

func _on_DynamicLabel_resized() -> void:
	if not resizeing and rect_size.distance_to(prev_size) > 1:
		resizeing = true
		set_process(true)
		prev_size = rect_size

func _process(_delta : float) -> void:
	if is_instance_valid(font) and resizeing:
		resizeing = false
		var size : Vector2
		var string_size := font.get_string_size(text)
		size = font.size * base_width_ratio * rect_size / string_size
		size = Vector2(floor(size.x), floor(size.y))
		if abs(min(size.x, size.y) - font.size) > 1:
			font.size = int(clamp(min(size.x, size.y), min_font_size, max_font_size))
	set_process(false)

func get_text_size(_text := "") -> Vector2:
	if _text == "":
		_text = text
	return font.get_string_size(_text)
