extends TextureRect

export (String, MULTILINE) var tooltip_text := ""


func _ready() -> void:
	Style.add(self, Style.c.LIGHT)
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")


func _on_mouse_entered() -> void:
	_g.emit_signal("tooltip", tooltip_text)


func _on_mouse_exited() -> void:
	_g.emit_signal("tooltip_hide")
