extends PanelContainer

var value : String = ""
var key : String = "" setget set_key, get_key
var file_name : String = "" setget set_file_name
var file_content_provided_manually := false

onready var line_edit := $HBoxContainer/VBoxContainer/GridContainer/LineEdit
onready var file_name_label := $HBoxContainer/VBoxContainer/GridContainer/FileNameLabel

var dragging := false

var drop_position = Vector2.ZERO

func set_file_name(_name : String):
	file_name = _name
	file_name_label.text = _name
	
func get_key() -> String:
	return line_edit.text
	
func set_key(_key : String):
	key = _key
	line_edit.text = _key


func _on_IconButton_pressed():
	queue_free()
	

