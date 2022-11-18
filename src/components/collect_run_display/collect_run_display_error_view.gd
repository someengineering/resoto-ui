extends PanelContainer

var filter := ""
var node_text := "" setget set_node_text
var node_text_lines : Array = []


onready var line_edit := $VBox/Title/AllDataFilter
onready var edit := $VBox/AllDataTextEdit
onready var max_btn := $VBox/Title/AllDataMaximizeButton


func _input(event):
	if event.is_action_pressed("search") and is_visible_in_tree():
		if get_global_rect().has_point(get_global_mouse_position()):
			line_edit.grab_focus()
			get_tree().set_input_as_handled()


func set_node_text(_node_text:String):
	node_text = _node_text
	node_text_lines = node_text.split("\n")
	apply_filter(filter)


func _on_AllDataFilter_text_changed(text):
	apply_filter(text.to_lower())


func apply_filter(_filter:String):
	filter = _filter
	if filter.strip_edges() == "":
		edit.text = node_text
		return
	
	var filtered_text:= ""
	var resulting_pos := -1
	for line in node_text_lines:
		if filter in line.to_lower():
			if resulting_pos == -1:
				resulting_pos = line.to_lower().find(filter)
			filtered_text += line + "\n"
	edit.text = filtered_text
	edit.select(0, resulting_pos, 0, resulting_pos+filter.length())


func _on_AllDataCopyButton_pressed():
	OS.set_clipboard(node_text)


func _on_AllDataMaximizeButton_pressed():
	hide()
