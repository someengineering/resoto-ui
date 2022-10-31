extends CanvasLayer
class_name PopupManager

signal popup_gone

var current_popup: Popup = null
var popup_connect: Node = null

onready var confirm_popup: Popup = $ConfirmPopup
onready var popup_bg := $BG
onready var tween := Tween.new()


func _enter_tree() -> void:
	_g.popup_manager = self


func _ready() -> void:
	add_child(tween)
	get_tree().root.connect("size_changed", self, "on_ui_scale_changed")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")


func open_popup(_name:String) -> void:
	if current_popup != null:
		on_popup_close()
		yield(self, "popup_gone")
	current_popup = (get_node(_name) as Popup)
	current_popup.connect("popup_hide", self, "on_popup_close", [], CONNECT_ONESHOT)
	current_popup.popup_centered_clamped(Vector2(1,1), 0.1)
	popup_fade_in()


func current_popup_to_null():
	current_popup = null
	emit_signal("popup_gone")


func popup_active() ->bool:
	return current_popup != null


func on_popup_close() -> void:
	tween.remove_all()
	tween.interpolate_property(popup_bg, "modulate:a", popup_bg.modulate.a, 0.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.1)
	tween.interpolate_property(current_popup, "modulate:a", current_popup.modulate.a, 0, 0.05, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_callback(popup_bg, 0.5, "hide")
	tween.interpolate_callback(current_popup, 0.05, "hide")
	tween.interpolate_callback(self, 0.06, "current_popup_to_null")
	tween.start()
	popup_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE


func popup_fade_in():
	tween.remove_all()
	popup_bg.show()
	popup_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.interpolate_property(popup_bg, "modulate:a", popup_bg.modulate.a, 1, 0.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
	current_popup.modulate.a = 0
	current_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.interpolate_property(current_popup, "modulate:a", current_popup.modulate.a, 1, 0.1)
	tween.start()


func show_confirm_popup(_title:String, _text:String, _left_button_text:String="Ok", _right_button_text:String="Cancel") -> Popup:
	if current_popup != null:
		on_popup_close()
		yield(self, "popup_gone")
	current_popup = confirm_popup
	confirm_popup.confirm_popup(_title, _text, _left_button_text, _right_button_text)
	current_popup.popup_centered_clamped(Vector2(1,1), 0.1)
	current_popup.connect("popup_hide", self, "on_popup_close", [], CONNECT_ONESHOT)
	
	popup_fade_in()
	return confirm_popup


func show_input_popup(_title:String, _text:String, _default_value:String="", _left_button_text:String="Ok", _right_button_text:String="Cancel") -> Popup:
	if current_popup != null:
		on_popup_close()
		yield(self, "popup_gone")
	current_popup = confirm_popup
	confirm_popup.input_popup(_title, _text, _default_value, _left_button_text, _right_button_text)
	current_popup.popup_centered_clamped(Vector2(1,1), 0.1)
	current_popup.connect("popup_hide", self, "on_popup_close", [], CONNECT_ONESHOT)
	
	popup_fade_in()
	return confirm_popup


func on_ui_scale_changed() -> void:
	if current_popup != null:
		var relative_window_size = OS.window_size / _g.ui_scale
		var popup_size = current_popup.rect_size
		current_popup.rect_position = relative_window_size/2 - popup_size/2
