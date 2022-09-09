tool
class_name ClippedLabel
extends Label

export var raw_text : String setget set_raw_text

func set_raw_text(new_raw_text : String) -> void:
	text = ""
	raw_text = new_raw_text
	var width := rect_size.x
	var font = get_font("font")
	var i : int = 0
	while font.get_string_size(text+"...  ").x < width:
		if i >= raw_text.length():
			break
		text += raw_text[i]
		i += 1
	if text != raw_text:
		text += "..."


func _on_ClippedLabel_resized():
	set_raw_text(raw_text)
