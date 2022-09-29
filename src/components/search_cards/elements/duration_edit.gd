extends HBoxContainer

func get_value():
	return str("%d%d") % [str($IntEdit.text), $Button/Popup.duration_type]


func clear():
	$IntEdit.clear()
	$Button/Popup.duration_type = "d"


func _on_Button_pressed():
	$Button/Popup.popup(Rect2($Button.rect_global_position, Vector2(20,20)))


func _on_Popup_update_duration_type(duration_name:String):
	$Button.text = duration_name
