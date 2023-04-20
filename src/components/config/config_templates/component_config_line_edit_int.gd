extends LineEdit
class_name LineEditInt

signal value_change_done(_int)

export (bool) var update_on_writing := true
export (String) var prefix := ""
export (String) var suffix := ""
export (int) var max_value := 1000000000 setget set_max_value
export (bool) var use_max_value := false
export (int) var min_value := 0 setget set_min_value
export (bool) var use_min_value := true

var old_text:String = ""

onready var LineEditRegEx = RegEx.new()


func _ready():
	LineEditRegEx.compile("^[-]?[0-9]*$")
	connect("text_changed", self, "on_text_changed")
	set_number(old_text)


func set_number(new_number:String):
	if is_inside_tree():
		on_text_changed(new_number)
		add_suffix_prefix(new_number)


func add_suffix_prefix(_text:String):
	if prefix == "" and suffix == "":
		text = str(_text)
	elif prefix == "":
		text = "%s %s" % [_text, suffix]
	elif suffix == "":
		text = "%s %s" % [prefix, _text]
	else:
		text = "%s %s %s" % [prefix, _text, suffix]


func set_max_value(_max_value:int):
	max_value = _max_value
	if int(old_text) > max_value:
		old_text = str(max_value)


func set_min_value(_min_value:int):
	min_value = _min_value
	if int(old_text) < min_value:
		old_text = str(min_value)


func on_text_changed(new_text:String):
	var old_cursor_pos = get_cursor_position()
	if not update_on_writing:
		return
	check_text(new_text)
	set_cursor_position(old_cursor_pos)

func check_text(new_text:String):
	if new_text == "":
		new_text = str(0)
	if LineEditRegEx.search(new_text):
		if use_max_value and int(new_text) > max_value:
			new_text = str(max_value)
		if use_min_value and int(new_text) < min_value:
			new_text = str(min_value)
		old_text = str(new_text)
		add_suffix_prefix(old_text)
	else:
		var cursor_pos = clamp(caret_position-1, 0, old_text.length())
		add_suffix_prefix(old_text)
		set_cursor_position(cursor_pos)
	emit_signal("value_change_done", int(old_text))


func _on_IntEdit_text_entered(_new_text):
	check_text(text)
	release_focus()
