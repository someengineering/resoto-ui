extends WizardEditorNode

var step_text:String = ""
var variable_check:String = ""
var docs_link:String = ""
var icon_path : String = ""
var custom_order:int = 0


func _ready():
	$Grid/OrderSpinnerBig.value = custom_order
	$Grid/TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	$Grid/DocsEdit.connect("text_changed", self, "_on_LineEdit_text_changed")
	$Grid/VariableCheckEdit.connect("text_changed", self, "_on_VariableCheckEdit_text_changed")
	$Grid/IconLineEdit.connect("text_changed", self, "_on_IconLineEdit_changed")

func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["docs_link"] = docs_link
	data["custom_order"] = custom_order
	data["variable_check"] = variable_check
	data["icon_path"] = icon_path
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	step_text = data["step_text"]
	docs_link = data["docs_link"]
	variable_check = data["variable_check"]
	custom_order = data["custom_order"]
	if "icon_path" in data:
		icon_path = data["icon_path"]
	$Grid/TextEdit.text = step_text
	$Grid/DocsEdit.text = docs_link
	$Grid/VariableCheckEdit.text = variable_check
	$Grid/OrderSpinnerBig.value = custom_order


func _on_TextEdit_text_changed():
	step_text = $Grid/TextEdit.text


func _on_LineEdit_text_changed(new_text):
	docs_link = new_text


func _on_OrderSpinnerBig_value_changed(value):
	custom_order = value


func _on_VariableCheckEdit_text_changed(new_text):
	variable_check = new_text


func _on_IconLineEdit_changed(new_text):
	icon_path = new_text
