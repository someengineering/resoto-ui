extends PanelContainer

var value : String = "" setget ,get_value
var key : String = "" setget ,get_key
var file_content_provided_manually := false

func get_value() -> String:
	return $HBoxContainer/VBoxContainer/GridContainer/TextEdit.text
	
func get_key() -> String:
	return $HBoxContainer/VBoxContainer/GridContainer/HBoxContainer/LineEdit.text


func _on_IconButton_pressed():
	queue_free()


func _on_CheckBox_pressed():
	file_content_provided_manually = not $HBoxContainer/VBoxContainer/GridContainer/HBoxContainer/CheckBox.pressed
	$HBoxContainer/VBoxContainer/GridContainer/Label2.visible = not file_content_provided_manually
	$HBoxContainer/VBoxContainer/GridContainer/TextEdit.visible = not file_content_provided_manually
