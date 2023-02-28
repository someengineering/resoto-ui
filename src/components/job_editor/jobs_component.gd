extends MarginContainer

signal show_section

func _ready():
	connect("visibility_changed", self, "_on_section_visibility_changed")


func _on_section_visibility_changed():
	emit_signal("show_section", visible)
