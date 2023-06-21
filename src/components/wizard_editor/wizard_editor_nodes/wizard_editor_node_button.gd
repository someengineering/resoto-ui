extends WizardEditorNode

var step_text:String = ""
var uid:String = ""

func _ready():
	$TextEdit.connect("text_changed", self, "_on_TextEdit_text_changed")
	

func _on_TextEdit_text_changed():
	step_text = $TextEdit.text


func _on_uidEdit_text_changed(new_text):
	uid = new_text


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["step_text"] = step_text
	data["uid"] = uid
	return data
	

func deserialize(data) -> void:
	base_deserialize(data)
	step_text = data["step_text"]
	uid = data["uid"]
	$top/uidEdit.text = uid
	$TextEdit.text = step_text
	
