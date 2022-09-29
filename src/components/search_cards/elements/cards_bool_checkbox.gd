extends CheckBox


func _on_CheckBox_pressed():
	text = "true" if pressed else "false"


func clear():
	pressed = false
	_on_CheckBox_pressed()
