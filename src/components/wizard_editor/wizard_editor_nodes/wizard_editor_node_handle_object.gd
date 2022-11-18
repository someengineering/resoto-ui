extends WizardEditorNode

var config_key:String = ""
var value_path:String = ""
var action:String = ""
var variable_name:String = ""
var wrap_as_array:bool = false


func _ready():
	$VariableEdit.connect("text_changed", self, "_on_VariableEdit_text_changed")
	$ConfigEdit.connect("text_changed", self, "_on_ConfigEdit_text_changed")
	$PathEdit.connect("text_changed", self, "_on_PathEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["config_key"] = config_key
	data["value_path"] = value_path
	data["variable_name"] = variable_name
	data["action"] = action
	data["wrap_as_array"] = wrap_as_array
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	config_key = data["config_key"]
	if data.has("value_path"):
		value_path = data["value_path"]
	if data.has("action"):
		action = data["action"]
	if data.has("wrap_as_array"):
		wrap_as_array = data["wrap_as_array"]
	variable_name = data["variable_name"]
	$ConfigEdit.text = config_key
	$PathEdit.text = value_path
	$VariableEdit.text = variable_name
	$WrapArrayCheckbox.pressed = wrap_as_array
	match action:
		"merge":
			$ActionOption.selected = 0
		"append":
			$ActionOption.selected = 1
		"set":
			$ActionOption.selected = 2


func _on_ConfigEdit_text_changed(new_text):
	config_key = new_text


func _on_PathEdit_text_changed(new_text):
	value_path = new_text


func _on_VariableEdit_text_changed(new_text):
	variable_name = new_text


func _on_ActionOption_item_selected(index):
	match index:
		0:
			action = "merge"
		1:
			action = "append"
		2:
			action = "set"


func _on_WrapArrayCheckbox_toggled(button_pressed):
	wrap_as_array = button_pressed
