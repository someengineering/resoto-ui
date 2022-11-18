extends WizardEditorNode

var docs_link:String = ""
var special_scene_path:String = ""
var uid:String = ""


func _ready():
	$DocsEdit.connect("text_changed", self, "_on_Docs_text_changed")
	$ScenePathEdit.connect("text_changed", self, "_on_ScenePathEdit_text_changed")


func serialize() -> Dictionary:
	var data:Dictionary = base_serialize()
	data["docs_link"] = docs_link
	data["special_scene_path"] = special_scene_path
	data["uid"] = uid
	return data


func deserialize(data) -> void:
	base_deserialize(data)
	docs_link = data["docs_link"]
	special_scene_path = data["special_scene_path"]
	uid = data["uid"]
	$top/uidEdit.text = uid
	$DocsEdit.text = docs_link
	$ScenePathEdit.text = special_scene_path


func _on_Docs_text_changed(new_text):
	docs_link = new_text


func _on_ScenePathEdit_text_changed():
	special_scene_path = $ScenePathEdit.text


func _on_uidEdit_text_changed(new_text):
	uid = new_text
