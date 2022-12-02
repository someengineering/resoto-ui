extends CanvasLayer
class_name PopupManager

signal popup_gone

var current_popup: Popup = null
var popup_connect: Node = null

var tooltip_link_active:= false
var tooltip_active:= false
var tooltip_error_active:= false

onready var n_tooltip_link:= $TooltipLayer/TooltipLink
onready var n_tooltip_error:= $TooltipLayer/ToolTipError
onready var n_tooltip:= $TooltipLayer/Tooltip
onready var confirm_popup: Popup = $ConfirmPopup
onready var popup_bg := $BG
onready var tween := Tween.new()
onready var main = get_parent()


func _enter_tree() -> void:
	_g.popup_manager = self


func _ready() -> void:
	add_child(tween)
	get_tree().root.connect("size_changed", self, "on_ui_scale_changed")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")
	_g.connect("tooltip", self, "tooltip")
	_g.connect("tooltip_error", self, "tooltip_error")
	_g.connect("tooltip_link", self, "tooltip_link")
	_g.connect("tooltip_hide", self, "tooltip_hide")
	_g.connect("text_to_clipboard", self, "on_text_to_clipboard")


func _process(_delta:float):
	if tooltip_active or tooltip_link_active or tooltip_error_active:
		var tt : Control = null
		if tooltip_active:
			tt = n_tooltip
		elif tooltip_link_active:
			tt = n_tooltip_link
		elif tooltip_error_active:
			tt = n_tooltip_error
		
		tt.rect_position = main.get_global_mouse_position() + Vector2(20,20)
		var w_rect := OS.get_window_safe_area()
		w_rect.size /= _g.ui_scale
		var tt_rect := tt.get_global_rect()
		# If the tooltip is outside the window
		if not w_rect.encloses(tt_rect):
			if tt_rect.end.x > w_rect.end.x:
				tt.rect_position.x = w_rect.end.x - tt_rect.size.x
			elif tt_rect.position.x < 0:
				tt.rect_position.x = 0
			if tt_rect.end.y > w_rect.end.y:
				tt.rect_position.y = w_rect.end.y - tt_rect.size.y
			elif tt_rect.position.y < 0:
				tt.rect_position.y = 0
		tt.show()


func tooltip(_text:String) -> void:
	n_tooltip.get_node("Text").set_bbcode(_text)
	tooltip_active = true


func tooltip_error(_text:String) -> void:
	n_tooltip_error.get_node("Text").set_bbcode(_text)
	tooltip_error_active = true


func tooltip_link(_title:String, _link:String) -> void:
	n_tooltip_link.get_node("VBox/HBox/DescrLabel").text = _title
	# LINK NOT WORKING!
	n_tooltip_link.get_node("VBox/UrlLabel").text = _link
	n_tooltip_link.rect_size = Vector2.ONE
	tooltip_link_active = true


func tooltip_hide() -> void:
	tooltip_link_active = false
	n_tooltip_link.visible = false
	tooltip_active = false
	n_tooltip.visible = false
	tooltip_error_active = false
	n_tooltip_error.visible = false


func on_text_to_clipboard(_text:String):
	OS.set_clipboard(_text)
	$TooltipLayer/CopyToClipboard.play()


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
	if current_popup == null:
		return
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
