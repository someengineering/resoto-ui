class_name ColorCondition
extends MarginContainer

signal condition_changed()

const var_text = "at %s"

var variable_name : String = "" setget set_variable_name
var value : float = 0.0 setget set_value
var color : Color = Color.black setget set_color

var condition : Array = [
	0,
	Color.black
]


func set_value(new_value : float):
	value = new_value
	$PanelContainer/HBoxContainer/SpinBox.value = value


func set_color(new_color : Color):
	color = new_color
	condition[1] = color
	emit_signal("condition_changed")
	$PanelContainer/HBoxContainer/HexColorPicker.color = color

func _on_SpinBox_value_changed(new_value):
	condition[0] = new_value
	emit_signal("condition_changed")


func set_variable_name(new_name : String):
	variable_name = var_text % new_name
	$PanelContainer/HBoxContainer/VariableLabel.text = variable_name


func _on_HexColorPicker_color_changed(new_color):
	condition[1] = new_color
	emit_signal("condition_changed")


func _on_DeleteButton_pressed():
	queue_free()
