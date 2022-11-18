extends RichTextLabel


func set_bbcode(_new:String):
	bbcode_text = _new
	adjust_size()


func adjust_size() -> void:
	var new_rect_min_size_x := 0.0
	for line in bbcode_text.split("\n"):
		new_rect_min_size_x = max(new_rect_min_size_x, get_font("normal_font").get_string_size(line).x)
	rect_min_size.x = new_rect_min_size_x
	rect_size.x = new_rect_min_size_x
	get_parent().rect_size = Vector2.ONE
