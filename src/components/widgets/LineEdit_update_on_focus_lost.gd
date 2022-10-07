extends LineEdit

func _ready():
	connect("focus_exited", self, "update_content")

func update_content():
	emit_signal("text_entered", text)
