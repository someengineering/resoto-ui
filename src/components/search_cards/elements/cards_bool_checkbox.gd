extends CheckBox


func _on_CheckBox_pressed():
	text = "true" if pressed else "false"
