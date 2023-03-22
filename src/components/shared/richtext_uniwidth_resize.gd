extends RichTextLabel


func set_bbcode(_new:String):
	bbcode_text = _new
	adjust_size()


func adjust_size() -> void:
	var new_rect_min_size_x := 0.0
	for line in text.split("\n"):
		new_rect_min_size_x = max(new_rect_min_size_x, get_font("normal_font").get_string_size(line).x) + 12.0
	var new_x_size := min(new_rect_min_size_x, OS.window_size.x - 12.0 )
	rect_min_size.x = new_x_size
	rect_size.x = new_x_size
	get_parent().rect_size = Vector2.ONE
