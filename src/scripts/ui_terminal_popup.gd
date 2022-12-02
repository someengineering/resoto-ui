extends CanvasLayer

const DEFAULT_POSITION := Vector2(130, 50)

var terminal_popup_rect := Rect2(0,0,0,0)
var hiding := false

onready var terminal_popup := $TerminalPopup
onready var tween = $VisibilityTween

func _ready():
	terminal_popup.modulate.a = 0.0
	_g.connect("resh_lite_popup", self, "change_terminal_popup_visibility")
	_g.connect("resh_lite_popup_hide", self, "hide_terminal_popup()")
	terminal_popup.set_window_title("Resoto Shell Lite")


func change_terminal_popup_visibility():
	if terminal_popup.visible and not hiding:
		hide_terminal_popup()
	else:
		show_terminal_popup()


func show_terminal_popup():
	tween.remove_all()
	hiding = false
	if terminal_popup_rect.size == Vector2(0,0):
		terminal_popup.show()
		tween.interpolate_property(terminal_popup, "modulate:a", terminal_popup.modulate.a, 1, 0.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(terminal_popup, "rect_position", DEFAULT_POSITION, DEFAULT_POSITION, 0.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(terminal_popup, "rect_scale", Vector2(1, 0.4), Vector2.ONE, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
		terminal_popup.rect_size = Vector2(900, 620)
	else:
		terminal_popup.show()
		terminal_popup.rect_pivot_offset = terminal_popup_rect.size/2
		tween.interpolate_property(terminal_popup, "modulate:a", terminal_popup.modulate.a, 1, 0.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(terminal_popup, "rect_position", terminal_popup_rect.position, terminal_popup_rect.position, 0.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(terminal_popup, "rect_scale", Vector2(1, 0.4), Vector2.ONE, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
		terminal_popup.rect_size = terminal_popup_rect.size


func hide_terminal_popup():
	tween.remove_all()
	terminal_popup_rect = terminal_popup.get_global_rect()
	terminal_popup.rect_pivot_offset = terminal_popup_rect.size/2
	tween.interpolate_property(terminal_popup, "modulate:a", terminal_popup.modulate.a, 0, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(terminal_popup, "rect_scale", Vector2.ONE, Vector2(1, 0.4), 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	hiding = true
	


func _on_TerminalPopup_close_popup():
	hide_terminal_popup()


func _on_VisibilityTween_tween_all_completed():
	if hiding:
		terminal_popup.hide()
