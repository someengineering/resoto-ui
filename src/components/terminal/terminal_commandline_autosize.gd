extends TextEdit

func _on_CommandEdit_text_changed():
	rect_min_size.y = get_total_visible_rows()*20
