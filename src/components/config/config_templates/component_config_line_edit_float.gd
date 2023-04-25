extends LineEdit
class_name LineEditFloat

var old_text:String = ""

onready var LineEditRegEx = RegEx.new()


func _ready():
	LineEditRegEx.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
	connect("text_changed", self, "on_text_changed")


func set_number(new_number:String):
	var old_cursor_pos = get_cursor_position()
	on_text_changed(new_number)
	text = old_text
	set_cursor_position(old_cursor_pos)


func on_text_changed(new_text:String):
	if new_text == "":
		new_text = str(0.0)
	if LineEditRegEx.search(new_text):
		old_text = str(new_text)
	else:
		var cursor_pos = clamp(caret_position-1, 0, old_text.length())
		text = old_text
		set_cursor_position(cursor_pos)
