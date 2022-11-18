extends WizardEditorNode

var variable_name:String = ""
var variable_value:String = ""


func _ready():
	$VariableNameEdit.connect("text_changed", self, "_on_VariableNameEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["variable_name"] = variable_name
	data["variable_value"] = variable_value
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	variable_name = data["variable_name"]
	variable_value = data["variable_value"]
	$VariableNameEdit.text = variable_name
	$VariableValueEdit.text = variable_value


func _on_VariableNameEdit_text_changed(new_text):
	variable_name = new_text


func _on_VariableValueEdit_text_changed(new_text):
	variable_value = new_text
