extends TextureRect

export var darker_color := false
export (String, MULTILINE) var tooltip_text := ""
export var link := ""


func _ready() -> void:
	if not darker_color:
		Style.add(self, Style.c.LIGHT)
	else:
		Style.add(self, Style.c.NORMAL)
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	if link != "":
		$Button.connect("pressed", self, "open_link")
	else:
		$Button.queue_free()

func _on_mouse_entered() -> void:
	_g.emit_signal("tooltip", tooltip_text)


func _on_mouse_exited() -> void:
	_g.emit_signal("tooltip_hide")


func open_link():
	OS.shell_open(link)
