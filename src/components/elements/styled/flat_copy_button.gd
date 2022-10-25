extends Button

const icon_check = preload("res://assets/icons/icon_128_check.svg")
const icon_copy = preload("res://assets/icons/icon_128_copy.svg")

var orig_alpha:= 1.0
onready var tween = $ClickEffectTween

func _ready():
	orig_alpha = modulate.a
	Style.add(self, Style.c.LIGHT)
	modulate.a = max(orig_alpha-0.2, 0.05)
	connect("pressed", self, "_on_IconButton_pressed")
	connect("mouse_entered", self, "_on_IconButton_mouse_entered")
	connect("mouse_exited", self, "_on_IconButton_mouse_exited")


func _on_IconButton_mouse_entered():
	if $ClickEffectTween.is_active():
		return
	modulate = Style.col_map[Style.c.LIGHT]
	modulate.a = orig_alpha


func _on_IconButton_mouse_exited():
	if $ClickEffectTween.is_active():
		return
	modulate = Style.col_map[Style.c.LIGHT]
	modulate.a = max(orig_alpha-0.2, 0.05)


func set_original_icon():
	icon = icon_copy


func _on_IconButton_pressed():
	icon = icon_check
	var old_color:= modulate
	old_color.a = max(orig_alpha-0.2, 0.05)
	tween.interpolate_property(self, "modulate", Color(0.2, 1.0, 0.35, 1.0), old_color, 1.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_callback(self, 0.8, "set_original_icon")
	tween.start()
