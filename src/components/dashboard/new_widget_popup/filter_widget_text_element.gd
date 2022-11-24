extends GridContainer

signal filter_element_changed(filter)

var filter_dict := {"filter_type" : "text", "content" : {"text": ""}}
var filter := "" setget set_filter

onready var text_edit := $FilterTextEdit


func get_filter() -> String:
	return filter


func set_filter(_filter:String):
	filter = _filter
	filter_dict.content.text = filter
	text_edit.text = filter


func _on_DeleteFilterButton_pressed():
	queue_free()


func _on_FilterTextEdit_text_entered(new_text):
	filter = new_text
	filter_dict.content.text = filter
	emit_signal("filter_element_changed")


func _on_FilterTextEdit_focus_exited():
	filter = text_edit.text
	filter_dict.content.text = filter
	emit_signal("filter_element_changed")


func _input(event:InputEvent):
	if (text_edit.has_focus()
	and event is InputEventMouseButton
	and event.is_pressed()
	and not text_edit.get_global_rect().has_point(event.position)):
		text_edit.release_focus()
