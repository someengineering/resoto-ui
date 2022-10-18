extends PopupPanel

signal change_scroll_pos

func show_all_data_popup(_data:String, _sv:=0):
	$VBox/AllDataTextEdit.text = _data
	var w_size = (OS.window_size / _g.ui_shrink)
	popup(Rect2(20, 164, w_size.x-40, w_size.y-184))
	$VBox/AllDataTextEdit.scroll_vertical = _sv


func _on_AllDataMaximizeButton_pressed():
	emit_signal("change_scroll_pos", $VBox/AllDataTextEdit.scroll_vertical)
	hide()
	
