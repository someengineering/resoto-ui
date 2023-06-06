extends IconButton

export (String) var url := ""

func _on_DocButton_pressed():
	OS.shell_open(url)
