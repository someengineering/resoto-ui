extends Control

signal filter_changed(filter)

onready var line_edit := $VBoxContainer/LineEdit
onready var labels := $VBoxContainer/GridContainer/Labels
onready var operators := $VBoxContainer/GridContainer/Operators
onready var value := $VBoxContainer/GridContainer/Value

func _on_Button_pressed() -> void:
	var filter = '%s%s"%s"' % [labels.text, operators.text, value.text]
	if filter in line_edit.text:
		return
	if line_edit.text != "":
		filter = ", "+filter
	line_edit.text += filter
	emit_signal("filter_changed", line_edit.text)


func _on_LineEdit_text_entered(new_text : String) -> void:
	emit_signal("filter_changed", new_text)


func _on_Labels_option_changed(option : String) -> void:
	API.tsdb_label_values(option, self)
	
func _on_tsdb_label_values_done(_error:int, response):
	var data = response.transformed.result
	if typeof(data) != TYPE_DICTIONARY:
		_g.emit_signal("add_toast", "No labels found", "Couldn't find labels for this filters.", 2, self)
		return
	var array := []
	for item in data.data:
		array.append(item)
		
	value.set_items(array)


func _on_LineEdit_focus_exited() -> void:
	emit_signal("filter_changed", line_edit.text)
