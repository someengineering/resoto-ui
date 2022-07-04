extends Control

signal filter_changed(filter)

onready var line_edit := $VBoxContainer/LineEdit
onready var labels := $VBoxContainer/GridContainer/Labels
onready var operators := $VBoxContainer/GridContainer/Operators
onready var value := $VBoxContainer/GridContainer/Value

func _on_Button_pressed():
	var filter = '%s%s"%s"' % [labels.text, operators.text, value.text]
	if filter in line_edit.text:
		return
	if line_edit.text != "":
		filter = ", "+filter
	line_edit.text += filter
	emit_signal("filter_changed", line_edit.text)


func _on_LineEdit_text_entered(new_text):
	emit_signal("filter_changed", new_text)


func _on_Labels_option_changed(option):
	API.tsdb_label_values(option, self)
	
func _on_tsdb_label_values_done(error:int, response):
	var data = response.transformed.result
	print(data)
	var array := []
	for item in data.data:
		array.append(item)
		
	value.set_items(array)


func _on_LineEdit_focus_exited():
	emit_signal("filter_changed", line_edit.text)
