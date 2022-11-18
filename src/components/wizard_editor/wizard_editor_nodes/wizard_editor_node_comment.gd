extends WizardEditorNode

var headline_text:String = "New Headline"


func _ready():
	$HeadlineEdit.connect("text_changed", self, "_on_HeadlineEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["headline_text"] = headline_text
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	headline_text = data["headline_text"]
	$HeadlineEdit.text = headline_text


func _on_HeadlineEdit_text_changed(new_text):
	headline_text = new_text
	call_deferred("_set_size", $HeadlineEdit.rect_min_size)
