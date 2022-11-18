extends WizardEditorNode

var step_text:String = ""
var docs_link:String = ""
var highlight_ids:String = ""
var previous_allowed:= true
var uid:String = ""


func _ready():
	$TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	$DocsEdit.connect("text_changed", self, "_on_LineEdit_text_changed")
	$HighlightEdit.connect("text_changed", self, "_on_HighlightEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["docs_link"] = docs_link
	data["highlight_ids"] = highlight_ids
	data["previous_allowed"] = previous_allowed
	data["uid"] = uid
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	step_text = data["step_text"]
	docs_link = data["docs_link"]
	highlight_ids = data["highlight_ids"]
	previous_allowed = data["previous_allowed"]
	uid = data["uid"]
	$top/uidEdit.text = uid
	$PrevBtn.pressed = previous_allowed
	$TextEdit.text = step_text
	$DocsEdit.text = docs_link
	$HighlightEdit.text = highlight_ids


func _on_TextEdit_text_changed():
	step_text = $TextEdit.text


func _on_LineEdit_text_changed(new_text):
	docs_link = new_text


func _on_HighlightEdit_text_changed(new_text):
	highlight_ids = new_text


func _on_PrevBtn_pressed():
	previous_allowed = $PrevBtn.pressed


func _on_uidEdit_text_changed(new_text):
	uid = new_text
