extends PopupPanel

signal open_script_file

onready var list = $Margin/VBox/ScrollContainer/ScriptList

func show_scripts(path):
	var available_scripts:= []
	
	var directory = Directory.new()
	var error = directory.open(path)
	if error == OK:
		directory.list_dir_begin(true, true)
		var file_name = directory.get_next()
		while (file_name != ""):
			if not directory.current_is_dir() and file_name.ends_with(".json"):
				available_scripts.append(file_name)
			file_name = directory.get_next()
	else:
		print("Error opening directory")
	
	for c in list.get_children():
		c.queue_free()
	
	for script in available_scripts:
		var new_button = Button.new()
		new_button.text = (script as String).trim_prefix("wizard_script_").trim_suffix(".json")
		new_button.connect("pressed", self, "_on_pressed_button", [script])
		new_button.theme_type_variation = "ButtonSmall"
		list.add_child(new_button)
	
	popup_centered(Vector2(300, 1))


func _on_pressed_button(file_name:String):
	emit_signal("open_script_file", file_name)
	hide()


func _on_CloseButton_pressed():
	hide()
