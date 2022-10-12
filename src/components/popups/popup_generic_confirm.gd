extends PopupDialog

signal response
signal response_with_input

var with_input:= false

onready var l_btn:Button = $Content/MarginContainer/Content/Buttons/LeftButton
onready var r_btn:Button = $Content/MarginContainer/Content/Buttons/RightButton
onready var line_edit:LineEdit = $Content/MarginContainer/Content/LineEdit

func _ready():
	Style.add_self(self, Style.c.BG_BACK)


func confirm_popup(_title:String, _text:String, _left_button_text:String="Ok", _right_button_text:String="Cancel"):
	with_input = false
	line_edit.hide()
	refresh_popup(_title, _text, _left_button_text, _right_button_text)


func input_popup(_title:String, _text:String, _default_value:String="", _left_button_text:String="Accept", _right_button_text:String="Cancel"):
	with_input = true
	line_edit.show()
	line_edit.text = _default_value
	line_edit.grab_focus()
	line_edit.set_cursor_position(_default_value.length())
	refresh_popup(_title, _text, _left_button_text, _right_button_text)


func refresh_popup(_title:String, _text:String, _left_button_text:String, _right_button_text:String):
	$Content/Label.text = _title
	$Content/MarginContainer/Content/Label.text = _text
	yield(VisualServer, "frame_post_draw")
	rect_size = $Content.rect_size
	if _g.os == "MacOS":
		l_btn.text = _right_button_text
		r_btn.text = _left_button_text
	else:
		l_btn.text = _left_button_text
		r_btn.text = _right_button_text


func _on_LeftButton_pressed():
	var button_pressed:= "right" if _g.os == "MacOS" else "left"
	send_response(button_pressed)
	hide()


func _on_RightButton_pressed():
	var button_pressed:= "left" if _g.os == "MacOS" else "right"
	send_response(button_pressed)
	hide()


func send_response(_button_pressed:String):
	if with_input:
		emit_signal("response_with_input", _button_pressed, line_edit.text)
	else:
		emit_signal("response", _button_pressed)


func _on_LineEdit_text_entered(_new_text):
	send_response("left")
	hide()
