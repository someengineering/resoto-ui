extends PanelContainer

signal toggled(_pressed)

var pressed := false setget set_pressed
var disabled := false setget set_disabled

onready var tween := $Tween
onready var box := $Box
onready var fill := $InnerBorder/InnerFill

func _ready():
	box.rect_min_size = Vector2(rect_size.y, rect_size.y)
	set_pressed(pressed, false)


func _on_CheckButtonStyled_toggled(_button_pressed:bool) -> void:
	set_pressed(_button_pressed, true)


func set_pressed(_pressed:bool, _emit_signal:=false) -> void:
	pressed = _pressed
	var new_pos = rect_size.x - box.rect_min_size.x if pressed else 0
	tween.interpolate_property(box, "rect_position:x", box.rect_position.x, new_pos, 0.1, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
	var new_color = Style.col_map[Style.c.LIGHT] if pressed else Style.col_map[Style.c.NORMAL]
	tween.interpolate_property(box, "modulate", box.modulate, new_color, 0.1, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
	var new_fill = Style.col_map[Style.c.NORMAL] if pressed else Style.col_map[Style.c.BG]
	tween.interpolate_property(fill, "modulate", fill.modulate, new_fill, 0.1, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
	tween.start()
	if _emit_signal:
		emit_signal("toggled", pressed)


func set_pressed_direct(_pressed:bool) -> void:
	pressed = _pressed
	box.rect_position.x = rect_size.x - box.rect_min_size.x if pressed else 0
	box.modulate = Style.col_map[Style.c.LIGHT] if pressed else Style.col_map[Style.c.NORMAL]
	fill.modulate = Style.col_map[Style.c.NORMAL] if pressed else Style.col_map[Style.c.BG]


func set_disabled(_disabled:bool) -> void:
	disabled = _disabled
	box.visible = !disabled
	modulate.a = 0.4 if disabled else 1.0
	$CheckButtonStyled.disabled = disabled
