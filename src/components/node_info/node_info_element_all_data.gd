extends PanelContainer

var persistent_key := "NodeInfoElement_AllDataFilterComboBox"
var filter_history := []
var filter := ""
var node_text := "" setget set_node_text
var node_text_lines : Array = []

onready var combo := $VBox/Title/AllDataFilter
onready var edit := $VBox/AllDataTextEdit

func _ready():
	if modulate != Color.white:
		Style.add(self, Style.find_color(modulate))
	elif self_modulate != Color.white:
		Style.add_self(self, Style.find_color(self_modulate))


func set_node_text(_node_text:String):
	node_text = _node_text
	node_text_lines = node_text.split("\n")
	apply_filter(filter)


func set_persistent_data(_data:Array):
	filter_history = _data
	combo.items = filter_history


func get_persistent_data() -> Dictionary:
	return {"key": persistent_key, "data": filter_history}


func _on_AllDataFilter_option_changed(option:String):
	if option.strip_edges() == "":
		return
	if filter_history.has(option):
		filter_history.erase(option)
	filter_history.push_front(option)
	if filter_history.size() > 20:
		filter_history.resize(20)
	SaveLoadSettings.save_settings()
	combo.items = filter_history
	apply_filter(option)


func _on_AllDataFilter_text_changed(text):
	apply_filter(text)


func apply_filter(_filter:String):
	filter = _filter
	if _filter.strip_edges() == "":
		edit.text = node_text
		return
	
	var filtered_text:= ""
	var resulting_pos := -1
	for line in node_text_lines:
		if _filter in line:
			if resulting_pos == -1:
				resulting_pos = line.find(_filter)
			filtered_text += line + "\n"
	edit.text = filtered_text
	edit.select(0, resulting_pos, 0, resulting_pos+_filter.length())


func _on_AllDataMaximizeButton_pressed():
	pass
	

func _on_AllDataCopyButton_pressed():
	OS.set_clipboard(node_text)
