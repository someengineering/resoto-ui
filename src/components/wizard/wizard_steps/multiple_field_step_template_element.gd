extends PanelContainer

var value : String = "" setget ,get_value
var key : String = "" setget ,get_key
var file_content_provided_manually := false

onready var line_edit = $HBoxContainer/VBoxContainer/GridContainer/LineEdit
onready var text_edit = $HBoxContainer/VBoxContainer/GridContainer/TextEdit

var dragging := false

var drop_position = Vector2.ZERO

func get_value() -> String:
	return text_edit.text
	
func get_key() -> String:
	return line_edit.text


func _on_IconButton_pressed():
	queue_free()
	

