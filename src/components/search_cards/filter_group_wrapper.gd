extends PanelContainer

signal delete
signal update_string

var main:Node = null setget set_main
var query_string:= ""


func set_main(_main):
	main = _main
	$FilterGroup.main = main


func _on_DeleteButton_pressed():
	emit_signal("delete")
	
