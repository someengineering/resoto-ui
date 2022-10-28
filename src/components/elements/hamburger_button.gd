extends Control

signal hamburger_button_pressed(pressed)

var pressed : bool = false setget set_pressed, get_pressed

onready var icon_close := $Button/CloseIcon
onready var icon_menu := $Button/MenuIcon
onready var btn := $Button
onready var tween := $Tween

func _on_Button_toggled(button_pressed):
	tween.interpolate_property(btn, "rect_scale", Vector2.ONE*0.5, Vector2.ONE, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(btn, "modulate", Color.white*2, Color.white, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	icon_close.visible = button_pressed
	icon_menu.visible = not button_pressed
	emit_signal("hamburger_button_pressed", button_pressed)


func set_pressed(value:bool):
	pressed = value
	_on_Button_toggled(pressed)


func get_pressed() -> bool:
	return pressed


func _on_HamburgerButton_pressed():
	set_pressed(!pressed)
