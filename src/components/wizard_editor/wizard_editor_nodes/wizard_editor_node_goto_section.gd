extends WizardEditorNode

var section_goto:String = ""


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["section_goto"] = section_goto
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	section_goto = data["section_goto"]
	$TextEdit.text = section_goto


func _on_TextEdit_text_changed(new_text:String) -> void:
	section_goto = new_text
