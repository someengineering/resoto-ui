extends Control

signal hamburger_button_pressed(pressed)

var pressed:bool = false setget set_pressed, get_pressed

onready var icon_close = $Button/CloseIcon
onready var icon_menu = $Button/MenuIcon

func _on_Button_toggled(button_pressed):
	$Tween.interpolate_property($Button, "rect_scale", Vector2.ONE*0.5, Vector2.ONE, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	icon_close.visible = button_pressed
	icon_menu.visible = not button_pressed
	emit_signal("hamburger_button_pressed", button_pressed)
	
func set_pressed(value:bool):
	$Button.pressed = value

func get_pressed() -> bool:
	return $Button.pressed
