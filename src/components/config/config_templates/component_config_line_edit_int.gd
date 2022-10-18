extends LineEdit
class_name LineEditInt

signal value_change_done(_int)

export (bool) var negative_allowed:= false setget set_negative_allowed

var old_text:String = ""

onready var LineEditRegEx = RegEx.new()


func _ready():
	set_negative_allowed(negative_allowed)
	connect("text_changed", self, "on_text_changed")
	set_number(old_text)


func set_negative_allowed(value:bool):
	var regex = "^[-]?[0-9]*$" if negative_allowed else "^[0-9]*$"
	LineEditRegEx.compile(regex)


func set_number(new_number:String):
	if self.is_inside_tree():
		on_text_changed(new_number)
	text = old_text


func on_text_changed(new_text:String):
	if new_text == "":
		new_text = str(0)
	if LineEditRegEx.search(new_text):
		old_text = str(new_text)
	else:
		var cursor_pos = clamp(caret_position-1, 0, old_text.length())
		text = old_text
		set_cursor_position(cursor_pos)
	emit_signal("value_change_done", int(old_text))
