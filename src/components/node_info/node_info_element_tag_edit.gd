extends PanelContainer

signal search_tag
signal change_tag
signal delete_tag

var value := "" setget set_value
var variable := "" setget set_variable

onready var val_edit := $VBox/Val/TagValue
onready var var_label := $VBox/Var/TagVariable


func set_variable(_variable:String):
	variable = _variable
	var_label.text = variable


func set_value(_value:String):
	value = _value
	val_edit.text = value


func _on_SearchTag_pressed():
	emit_signal("search_tag", "tags.%s==\"%s\"" % [variable, value])


func _on_DeleteTag_pressed():
	emit_signal("delete_tag", variable)


func change_tag():
	emit_signal("change_tag", variable, val_edit.text)


func _on_TagValue_text_entered(_new_text):
	change_tag()


func _on_TagValue_focus_exited():
	change_tag()


func _input(event:InputEvent):
	if (val_edit.has_focus()
	and event is InputEventMouseButton
	and event.is_pressed()
	and not val_edit.get_global_rect().has_point(event.position)):
		val_edit.release_focus()
