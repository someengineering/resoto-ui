extends TextureRect

export (String, MULTILINE) var hint := ""


func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")


func _on_mouse_entered() -> void:
	_g.emit_signal("tooltip", hint)


func _on_mouse_exited() -> void:
	_g.emit_signal("tooltip_hide")
