extends Button

var orig_alpha:= 1.0


func _ready():
	orig_alpha = modulate.a
	Style.add(self, Style.c.LIGHT)
	modulate.a = max(orig_alpha-0.2, 0.05)
	connect("pressed", self, "_on_IconButton_mouse_exited")
	connect("mouse_entered", self, "_on_IconButton_mouse_entered")
	connect("mouse_exited", self, "_on_IconButton_mouse_exited")


func _on_IconButton_mouse_entered():
	modulate = Style.col_map[Style.c.LIGHT]
	modulate.a = orig_alpha


func _on_IconButton_mouse_exited():
	modulate = Style.col_map[Style.c.LIGHT]
	modulate.a = max(orig_alpha-0.2, 0.05)
