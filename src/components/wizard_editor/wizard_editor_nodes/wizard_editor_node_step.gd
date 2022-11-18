extends WizardEditorNode

var step_text:String = ""
var docs_link:String = ""
var previous_allowed:bool = true


func _ready():
	$TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	$DocsEdit.connect("text_changed", self, "_on_LineEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["docs_link"] = docs_link
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	step_text = data["step_text"]
	docs_link = data["docs_link"]
	$TextEdit.text = step_text
	$DocsEdit.text = docs_link


func _on_TextEdit_text_changed():
	step_text = $TextEdit.text


func _on_LineEdit_text_changed(new_text):
	docs_link = new_text
