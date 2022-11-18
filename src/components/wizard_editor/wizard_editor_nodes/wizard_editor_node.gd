extends GraphNode
class_name WizardEditorNode

var res_name:String = ""
var step_id:int = -1


func _ready():
	connect("resize_request", self, "_on_resize_request")


func _on_resize_request(_new_size:Vector2):
	rect_size = Vector2(round(_new_size.x/20.0)*20.0, round(_new_size.y/20.0)*20.0)


func base_serialize() -> Dictionary:
	var _data:Dictionary
	_data["id"] = step_id
	_data["res_name"] = res_name
	_data["offset"] = var2str(offset)
	_data["rect_size"] = var2str(rect_size)
	return _data


func base_deserialize(data) -> void:
	step_id = data["id"]
	offset = str2var(data["offset"])
	rect_size = str2var(data["rect_size"])
