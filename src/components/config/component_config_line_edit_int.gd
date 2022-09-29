extends LineEdit
class_name LineEditInt

export var old_text:String = ""

onready var LineEditRegEx = RegEx.new()


func _ready():
	LineEditRegEx.compile("^[-]?[0-9]*$")
	connect("text_changed", self, "on_text_changed")
	set_number(old_text)


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

func clear():
	text = ""
