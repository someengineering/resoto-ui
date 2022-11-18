extends WizardEditorNode

var config_key:String = ""
var value_path:String = ""
var action:String = ""
var value:String = ""


func _ready():
	$ConfigEdit.connect("text_changed", self, "_on_ConfigEdit_text_changed")
	$PathEdit.connect("text_changed", self, "_on_PathEdit_text_changed")
	$ActionOption.connect("item_selected", self, "_on_ActionOption_selected")
	$ValueEdit.connect("text_changed", self, "_on_ValueEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["config_key"] = config_key
	data["value_path"] = value_path
	data["action"] = action
	data["value"] = value
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	config_key = data["config_key"]
	if data.has("value_path"):
		value_path = data["value_path"]
	action = data["action"]
	value = data["value"]
	
	$ConfigEdit.text = config_key
	$PathEdit.text = value_path
	$ValueEdit.text = value
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


func _on_ActionOption_selected(index):
	match index:
		0:
			action = "merge"
		1:
			action = "append"
		2:
			action = "set"


func _on_ValueEdit_text_changed(new_text):
	value = new_text
