extends PanelContainer

const icon_check = preload("res://assets/icons/icon_128_check.svg")
const icon_copy = preload("res://assets/icons/icon_128_copy.svg")

const OFFSET := Vector2(15, -17)

onready var tween := $Tween
onready var icon := $HBoxContainer/CopyIcon


func _ready():
	Style.add(icon, Style.c.LIGHT)


func play(_position:Vector2 = get_global_mouse_position()):
	tween.remove_all()
	show()
	var move_x_distance := 10
	if (_position.x + OFFSET.x + rect_min_size.x + move_x_distance) < OS.get_window_size().x:
		rect_global_position = _position + OFFSET
	else:
		move_x_distance = -10
		rect_global_position = _position + OFFSET - Vector2(rect_min_size.x, 0) - Vector2(10, 0)
	icon.texture = icon_copy
	tween.interpolate_property(self, "rect_position:x", rect_position.x, rect_position.x + move_x_distance, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 0, 1, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 1, 0, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN, 0.1)
	var old_color : Color = icon.modulate
	tween.interpolate_property(icon, "modulate", Color(0.2, 1.0, 0.35, 1.0), old_color, 1.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.15)
	tween.interpolate_callback(self, 0.15, "set_copy_icon")
	tween.start()


func _on_Tween_tween_all_completed():
	hide()

func set_copy_icon():
	icon.texture = icon_check
