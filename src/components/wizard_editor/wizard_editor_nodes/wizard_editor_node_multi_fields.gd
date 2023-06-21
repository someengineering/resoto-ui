extends WizardEditorNode

var step_text:String = ""
var docs_link:String = ""
var config_key:String = ""
var value_path:String = ""
var action:String = "merge"
var format:String = ""
var out_data_format:String = ""
var id_field_name : String = ""
var content_name : String = ""
var single_content : bool = false
var drop_label_text := ""
var special_scene_path:String = ""
var previous_allowed:= true
var uid:String = ""


func _ready():
	$TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	$DocsEdit.connect("text_changed", self, "_on_LineEdit_text_changed")
	$Grid/ConfigEdit.connect("text_changed", self, "_on_ConfigEdit_text_changed")
	$Grid/PathEdit.connect("text_changed", self, "_on_PathEdit_text_changed")
	$Grid/ActionOption.connect("item_selected", self, "_on_ActionOption_selected")
	$ScenePathEdit.connect("text_changed", self, "_on_ScenePathEdit_text_changed")
	$Grid/FormatLineEdit.connect("text_changed", self, "_on_FormatLineEdit_text_changed")
	$HBoxContainer/OutDataLineEdit.connect("text_changed", self, "_on_OutDataLineEdit_text_changed")
	$Grid/IdFieldName.connect("text_changed", self, "_on_IdFieldName_text_changed")
	$Grid/ContentName.connect("text_changed", self, "_on_ContentName_text_changed")
	$Grid/SingleFileCheckBox.connect("toggled", self, "_on_SingleFileCheckBox_toggled")
	$Grid/DropLabelTextLineEdit.connect("text_changed", self, "_on_DropLabelTextLineEdit_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["docs_link"] = docs_link
	data["config_key"] = config_key
	data["value_path"] = value_path
	data["action"] = action
	data["special_scene_path"] = special_scene_path
	data["previous_allowed"] = previous_allowed
	data["uid"] = uid
	data["format"] = format
	data["out_data_format"] = out_data_format
	data["id_field_name"] = id_field_name
	data["content_name"] = content_name
	data["single_content"] = single_content
	data["drop_label_text"] = drop_label_text
	return data
	
func deserialize(data) -> void:
	base_deserialize(data)
	for key in data:
		set(key, data[key])
	$top/uidEdit.text = uid
	$PrevBtn.pressed = previous_allowed
	$TextEdit.text = step_text
	$DocsEdit.text = docs_link
	$Grid/ConfigEdit.text = config_key
	$Grid/PathEdit.text = value_path
	$ScenePathEdit.text = special_scene_path
	$Grid/FormatLineEdit.text = format
	$HBoxContainer/OutDataLineEdit.text = out_data_format
	$Grid/IdFieldName.text  = id_field_name
	$Grid/ContentName.text = content_name
	$Grid/SingleFileCheckBox.pressed = single_content
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


func _on_ScenePathEdit_text_changed(new_text):
	special_scene_path = new_text


func _on_PrevBtn_pressed():
	previous_allowed = $PrevBtn.pressed


func _on_uidEdit_text_changed(new_text):
	uid = new_text


func _on_FormatLineEdit_text_changed(new_text):
	format = new_text

func _on_OutDataLineEdit_text_changed(new_text):
	out_data_format = new_text


func _on_IdFieldName_text_changed(new_text):
	id_field_name = new_text

func _on_ContentName_text_changed(new_text):
	content_name = new_text

func _on_SingleFileCheckBox_toggled(value : bool):
	single_content = value
	
func _on_DropLabelTextLineEdit_changed(new_text : String):
	drop_label_text = new_text
