extends "res://components/elements/styled/icon_button.gd"
tool

const icon_true = preload("res://assets/icons/icon_128_checkbox_true.svg")
const icon_false = preload("res://assets/icons/icon_128_checkbox_false.svg")


func _ready():
	connect("toggled", self, "_on_toggle")
	_on_toggle(pressed)


func _on_toggle(_value:bool):
	var new_icon_tex = icon_true if _value else icon_false
	set_icon_tex(new_icon_tex)
