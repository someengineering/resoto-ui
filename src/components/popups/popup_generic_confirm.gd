extends PopupDialog

signal response

onready var l_btn = $Content/MarginContainer/Content/Buttons/LeftButton
onready var r_btn = $Content/MarginContainer/Content/Buttons/RightButton


func confirm_popup(_title:String, _text:String, _left_button_text:String="Ok", _right_button_text:String="Cancel"):
	$Content/Label.text = _title
	$Content/MarginContainer/Content/Label.text = _text
	rect_size = $Content/MarginContainer.rect_size
	if _g.os == "MacOS":
		l_btn.text = _right_button_text
		r_btn.text = _left_button_text
	else:
		l_btn.text = _left_button_text
		r_btn.text = _right_button_text


func _on_LeftButton_pressed():
	if _g.os == "MacOS":
		emit_signal("response", "right")
	else:
		emit_signal("response", "left")
	hide()


func _on_RightButton_pressed():
	if _g.os == "MacOS":
		emit_signal("response", "left")
	else:
		emit_signal("response", "right")
	hide()
