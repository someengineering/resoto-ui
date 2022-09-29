extends HBoxContainer

signal update_string

func _ready():
	clear()


func get_value():
	var val = str($IntEdit.text)
	val = val if val != "" else "1"
	return str("%s%s") % [val, $Button/Popup.duration_type]


func clear():
	$IntEdit.text = "1"
	$Button/Popup.duration_type = "d"
	emit_signal("update_string")


func _on_Button_pressed():
	$Button/Popup.popup(Rect2($Button.rect_global_position, Vector2(20,20)))


func _on_Popup_update_duration_type(duration_name:String):
	$Button.text = duration_name
	emit_signal("update_string")


func _on_IntEdit_text_changed(new_text):
	emit_signal("update_string")
