extends WizardEditorNode

var section_name:String = ""
var section_display_title:String = ""


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["section_name"] = section_name
	data["section_display_title"] = section_display_title
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	section_name = data["section_name"]
	section_display_title = data["section_display_title"]
	$TextEdit.text = section_name
	var title_node = $SectionTitleTextEdit
	if title_node:
		title_node.text = section_display_title


func _on_TextEdit_text_changed(new_text:String) -> void:
	section_name = new_text


func _on_SectionTitleTextEdit_text_changed(new_text):
	section_display_title = new_text
