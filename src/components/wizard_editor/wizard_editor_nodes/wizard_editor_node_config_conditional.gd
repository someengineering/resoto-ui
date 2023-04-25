extends WizardEditorNode

var variable_name:String = ""
var variable_value:String = ""
var config:String = ""
var operation:String = ""
var kind:String = ""


func _ready():
	$Grid/VariableNameEdit.connect("text_changed", self, "_on_VariableNameEdit_text_changed")
	$Grid/VariableValueEdit.connect("text_changed", self, "_on_VariableValueEdit_text_changed")
	$Grid/ConfigEdit.connect("text_changed", self, "_on_ConfigEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["variable_name"] = variable_name
	data["variable_value"] = variable_value
	data["operation"] = operation
	data["config"] = config
	data["kind"] = kind
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	variable_name = data["variable_name"]
	variable_value = data["variable_value"]
	operation = data["operation"]
	config = data["config"]
	kind = data["kind"]
	$Grid/VariableNameEdit.text = variable_name
	$Grid/VariableValueEdit.text = variable_value
	$Grid/ConfigEdit.text = config
	for i in $Grid/OperationButton.get_item_count():
		if $Grid/OperationButton.get_item_text(i) == operation:
			$Grid/OperationButton.select(i)
	for i in $Grid/KindButton.get_item_count():
		if $Grid/KindButton.get_item_text(i) == kind:
			$Grid/KindButton.select(i)


func _on_VariableNameEdit_text_changed(new_text):
	variable_name = new_text


func _on_VariableValueEdit_text_changed(new_text):
	variable_value = new_text


func _on_ConfigEdit_text_changed(new_text):
	config = new_text


func _on_OperationButton_item_selected(index):
	operation = $Grid/OperationButton.get_item_text(index)


func _on_KindButton_item_selected(index):
	kind = $Grid/KindButton.get_item_text(index)
