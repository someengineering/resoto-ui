extends WizardEditorNode

var variable_name:String = ""


func _ready():
	$VariableNameEdit.connect("text_changed", self, "_on_VariableNameEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["variable_name"] = variable_name
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	variable_name = data["variable_name"]
	$VariableNameEdit.text = variable_name


func _on_VariableNameEdit_text_changed(new_text):
	variable_name = new_text
