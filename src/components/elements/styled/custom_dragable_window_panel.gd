extends PanelContainer
class_name CustomPopupWindowContainer

signal popup_hide
signal about_to_show

const TopMenuHeight:= 40

export (PackedScene) var window_content : PackedScene
export var default_size:= Vector2(200, 200)
export var window_title:= "Window Title" setget set_window_title
export var show_close_icon:= true
export var show_max_icon:= true
export var show_footer:= true
export var can_drag:= true
export var can_resize:= true
export var content_margin_left_right:= Vector2(10,10)
export var content_margin_top_bottom:= Vector2(10,10)

var is_dragging:= false
var is_maximized:= false
var drag_start_position:= Vector2.ONE
var size_before_max:= Vector2.ONE
var pos_before_max:= Vector2.ONE
var is_resizing:= false
var orig_size:= Vector2.ONE
var resize_click_origin:= Vector2.ONE

onready var max_btn = $Content/Titlebar/Label/TitleButtons/MaximizeButton
onready var close_btn = $Content/Titlebar/Label/TitleButtons/CloseButton
onready var resize_btn = $ResizeButtonContainer/ResizeButton

func _ready():
	hide()
	rect_size = default_size
	size_before_max = default_size
	$Content/Content.add_constant_override("margin_left", content_margin_left_right.x)
	$Content/Content.add_constant_override("margin_right", content_margin_left_right.y)
	$Content/Content.add_constant_override("margin_top", content_margin_top_bottom.x)
	$Content/Content.add_constant_override("margin_bottom", content_margin_top_bottom.y)
	$Content/Titlebar.target = self
	connect("visibility_changed", self, "_on_change_visibility")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")
	set_window_title(window_title)
	$Content/Footer.visible = show_footer
	if window_content != null:
		var new_content = window_content.instance()
		$Content/Content.add_child(new_content)


func popup_centered():
	show()
	var w_size = (OS.window_size / _g.ui_scale)
	rect_global_position = (w_size/2 - rect_size/2) - Vector2(0, -TopMenuHeight)


func on_ui_scale_changed() -> void:
	if visible:
		var w_size = (OS.window_size / _g.ui_scale)
		rect_global_position = (w_size/2 - rect_size/2) - Vector2(0, -TopMenuHeight)
		rect_size = Vector2(
			clamp(rect_size.x, 1, w_size.x - rect_global_position.x),
			clamp(rect_size.y, 1, w_size.y - rect_global_position.y)
		)


func set_window_title(_new_title:String):
	window_title = _new_title
	$Content/Titlebar/Label.text = _new_title


func _on_change_visibility():
	if visible:
		emit_signal("about_to_show")
		reset_settings()


func reset_settings():
	resize_btn.visible = can_resize
	close_btn.visible = show_close_icon
	max_btn.visible = show_max_icon
	rect_size = size_before_max


func _process(_delta:float):
	if not visible or ((is_dragging or is_resizing) and not Input.is_mouse_button_pressed(BUTTON_LEFT)):
		is_dragging = false
		is_resizing = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		set_process(false)
	
	var w_size = OS.window_size / _g.ui_scale
	if is_dragging:
		var m_pos = get_global_mouse_position() - drag_start_position
		rect_global_position = Vector2(
			clamp(m_pos.x, 0, w_size.x - rect_size.x),
			clamp(m_pos.y, TopMenuHeight, w_size.y - rect_size.y)
		)
	
	if is_resizing:
		var n_size = orig_size + (get_global_mouse_position() - resize_click_origin)
		rect_size = Vector2(
			clamp(n_size.x, 1, w_size.x - rect_global_position.x),
			clamp(n_size.y, 1, w_size.y - rect_global_position.y)
		)
		size_before_max = rect_size


func start_drag(_drag_position:Vector2):
	if not can_drag:
		return
	var maximized_offset:= Vector2.ZERO
	if is_maximized:
		is_maximized = false
		max_btn.pressed = false
		maximized_offset.x = 0 if _drag_position.x <= size_before_max.x else int((_drag_position.x - size_before_max.x) + size_before_max.x*0.5)
		rect_size = size_before_max
	
	is_dragging = true
	set_process(true)
	drag_start_position = _drag_position - maximized_offset


func _hide_popup():
	hide()
	emit_signal("popup_hide")


func _on_ResizeButton_button_down():
	if not can_resize or is_resizing:
		return
	if is_maximized:
		is_maximized = false
		max_btn.pressed = false
	
	is_resizing = true
	set_process(true)
	Input.set_default_cursor_shape(Input.CURSOR_BDIAGSIZE)
	resize_click_origin = get_global_mouse_position()
	orig_size = rect_size


func _on_MaximizeButton_pressed():
	is_maximized = max_btn.pressed
	if is_maximized:
		size_before_max = rect_size
		pos_before_max = rect_position
		rect_position = Vector2(0, TopMenuHeight)
		rect_size = (OS.window_size / _g.ui_scale) + Vector2(0, -TopMenuHeight)
	else:
		rect_position = pos_before_max
		rect_size = size_before_max


func _on_CloseButton_pressed():
	_hide_popup()
