extends WizardEditorNode

var step_text:String = ""
var docs_link:String = ""
var config_key:String = ""
var value_path:String = ""
var separator:String = ""
var action:String = "merge"
var special_scene_path:String = ""
var previous_allowed:= true
var uid:String = ""


func _ready():
	$TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	$DocsEdit.connect("text_changed", self, "_on_LineEdit_text_changed")
	$Grid/ConfigEdit.connect("text_changed", self, "_on_ConfigEdit_text_changed")
	$Grid/PathEdit.connect("text_changed", self, "_on_PathEdit_text_changed")
	$Grid/ActionOption.connect("item_selected", self, "_on_ActionOption_selected")
	$Grid/SeparatorEdit.connect("text_changed", self, "_on_SeparatorEdit_text_changed")
	$ScenePathEdit.connect("text_changed", self, "_on_ScenePathEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["docs_link"] = docs_link
	data["config_key"] = config_key
	data["value_path"] = value_path
	data["action"] = action
	data["separator"] = separator
	data["special_scene_path"] = special_scene_path
	data["previous_allowed"] = previous_allowed
	data["uid"] = uid
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	step_text = data["step_text"]
	docs_link = data["docs_link"]
	config_key = data["config_key"]
	value_path = data["value_path"]
	action = data["action"]
	separator = data["separator"]
	special_scene_path = data["special_scene_path"]
	previous_allowed = data["previous_allowed"]
	uid = data["uid"]
	$top/uidEdit.text = uid
	$PrevBtn.pressed = previous_allowed
	$TextEdit.text = step_text
	$DocsEdit.text = docs_link
	$Grid/ConfigEdit.text = config_key
	$Grid/PathEdit.text = value_path
	$Grid/SeparatorEdit.text = separator
	$ScenePathEdit.text = special_scene_path
	match action:
		"merge":
			$Grid/ActionOption.selected = 0
		"append":
			$Grid/ActionOption.selected = 1
		"set":
			$Grid/ActionOption.selected = 2


func _on_TextEdit_text_changed():
	step_text = $TextEdit.text


func _on_LineEdit_text_changed(new_text):
	docs_link = new_text


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


func _on_SeparatorEdit_text_changed(new_text):
	separator = new_text


func _on_ScenePathEdit_text_changed(new_text):
	special_scene_path = new_text


func _on_PrevBtn_pressed():
	previous_allowed = $PrevBtn.pressed


func _on_uidEdit_text_changed(new_text):
	uid = new_text
