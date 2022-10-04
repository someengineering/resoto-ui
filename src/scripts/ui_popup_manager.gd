extends CanvasLayer

var current_popup: Popup = null
var popup_connect: Node = null

onready var confirm_popup: Popup = $ConfirmPopup
onready var popup_bg = $BG


func _enter_tree() -> void:
	_g.popup_manager = self


func _ready() -> void:
	get_tree().root.connect("size_changed", self, "on_ui_shrink_changed")
	_g.connect("ui_shrink_changed", self, "on_ui_shrink_changed")


func on_popup_close() -> void:
	popup_bg.hide()
	current_popup.hide()
	current_popup = null


func show_confirm_popup(_title:String, _text:String, _left_button_text:String="Ok", _right_button_text:String="Cancel") -> Popup:
	popup_bg.show()
	if current_popup != null:
		current_popup.hide()
	current_popup = confirm_popup
	confirm_popup.confirm_popup(_title, _text, _left_button_text, _right_button_text)
	confirm_popup.popup_centered_clamped(Vector2(0,0), 2.2)
	current_popup.connect("popup_hide", self, "on_popup_close", [], CONNECT_ONESHOT)
	return confirm_popup


func popup_active() ->bool:
	return current_popup != null


func open_popup(_name:String) -> void:
	popup_bg.show()
	current_popup = (get_node(_name) as Popup)
	current_popup.connect("popup_hide", self, "on_popup_close", [], CONNECT_ONESHOT)
	current_popup.popup_centered_clamped(Vector2(0,0), 2.2)


func on_ui_shrink_changed() -> void:
	if current_popup != null:
		var relative_window_size = OS.window_size / _g.ui_shrink
		var popup_size = current_popup.rect_size
		current_popup.rect_position = relative_window_size/2 - popup_size/2
