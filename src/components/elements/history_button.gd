extends ToolButton
tool

export var px_offset := 8.0
export var forward : bool = false setget set_forward
export var can_press : bool = true setget set_can_press

onready var icon_arrow := $Button/ArrowIcon
onready var btn := $Button
onready var tween := $Tween


func _ready():
	connect("pressed", self, "_on_Button_pressed")


func _on_Button_pressed():
	var target_pos = px_offset if forward else -px_offset
	tween.interpolate_property(icon_arrow, "rect_scale", Vector2(0.2, 0.6), Vector2.ONE, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(btn, "rect_position:x", btn.rect_position.x, target_pos, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(btn, "rect_position:x", target_pos, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.1)
	tween.interpolate_property(icon_arrow, "modulate", Color.white*2, Color.white, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	release_focus()


func set_forward(_forward:bool) -> void:
	forward = _forward
	$Button/ArrowIcon.flip_h = forward


func set_can_press(_can_press:bool) -> void:
	can_press = _can_press
	disabled = !can_press
	if tween and btn:
		var alpha_target : float = 1.0 if can_press else 0.2
		tween.interpolate_property(btn, "modulate:a", btn.modulate.a, alpha_target, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
	else:
		$Button.modulate.a = 1.0 if can_press else 0.2
