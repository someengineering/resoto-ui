extends LineEdit
class_name LineEditInt

signal value_change_done(_int)

export (bool) var update_on_writing := true
export (String) var prefix := ""
export (String) var suffix := ""
export (bool) var negative_allowed:= false setget set_negative_allowed
export (int) var max_value := 1000000000 setget set_max_value
export (bool) var use_max_value := false

var old_text:String = ""

onready var LineEditRegEx = RegEx.new()


func _ready():
	set_negative_allowed(negative_allowed)
	connect("text_changed", self, "on_text_changed")
	set_number(old_text)


func set_negative_allowed(_negative_allowed:bool):
	negative_allowed = _negative_allowed
	var regex = "^[-]?[0-9]*$" if negative_allowed else "^[0-9]*$"
	LineEditRegEx.compile(regex)


func set_number(new_number:String):
	if is_inside_tree():
		on_text_changed(new_number)
	text = "%s %s %s" % [prefix, old_text, suffix]


func set_max_value(_max_value:int):
	max_value = _max_value
	if int(old_text) > max_value:
		old_text = str(max_value)


func on_text_changed(new_text:String):
	if not update_on_writing:
		return
	check_text(new_text)

func check_text(new_text:String):
	if new_text == "":
		new_text = str(0)
	if LineEditRegEx.search(new_text):
		if use_max_value and int(new_text) > max_value:
			new_text = str(max_value)
		old_text = str(new_text)
		text = "%s %s %s" % [prefix, old_text, suffix]
	else:
		var cursor_pos = clamp(caret_position-1, 0, old_text.length())
		text = "%s %s %s" % [prefix, old_text, suffix]
		set_cursor_position(cursor_pos)
	emit_signal("value_change_done", int(old_text))


func _on_IntEdit_text_entered(new_text):
	check_text(text)
	release_focus()
