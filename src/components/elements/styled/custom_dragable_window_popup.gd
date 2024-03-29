extends PopupPanel
class_name CustomPopupWindow

signal close_popup

const TopMenuHeight:= 40

export var default_size:= Vector2.ONE
export var show_close_icon:= true
export var show_max_icon:= true
export var can_drag:= true
export var can_resize:= true

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
	$Content/Titlebar.target = self
	connect("about_to_show", self, "reset_settings")
	rect_size = default_size
	get_tree().root.connect("size_changed", self, "on_ui_scale_changed")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")


func on_ui_scale_changed() -> void:
	if visible:
		var w_size = (OS.window_size / _g.ui_scale)
		
		if get_global_rect().end.x > w_size.x:
			rect_position.x = w_size.x - get_global_rect().size.x
		if get_global_rect().end.y > w_size.y:
			rect_position.y = w_size.y - get_global_rect().size.y
		
		if get_global_rect().position.y < TopMenuHeight:
			rect_size.y = w_size.y - TopMenuHeight
			rect_position.y = TopMenuHeight
		if get_global_rect().position.x < 0:
			rect_size.x = w_size.x
			rect_position.x = 0


func set_window_title(_new_title:String):
	$Content/Titlebar/Label.text = _new_title


func reset_settings():
	resize_btn.visible = can_resize
	close_btn.visible = show_close_icon
	max_btn.visible = show_max_icon
	rect_size = size_before_max
	on_ui_scale_changed()


func _process(_delta:float):
	if not visible or ((is_dragging or is_resizing) and not Input.is_mouse_button_pressed(BUTTON_LEFT)):
		is_dragging = false
		is_resizing = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		set_process(false)
	
	var w_size = OS.window_size / _g.ui_scale
	if is_dragging:
		var m_pos = get_global_mouse_position() - drag_start_position
		rect_position = Vector2(
			clamp(m_pos.x, 0, w_size.x - rect_size.x),
			clamp(m_pos.y, TopMenuHeight, w_size.y - rect_size.y)
		)
	
	if is_resizing:
		var n_size = orig_size + (get_global_mouse_position() - resize_click_origin)
		rect_size = Vector2(
			clamp(n_size.x, 1, w_size.x - rect_position.x),
			clamp(n_size.y, 1, w_size.y - rect_position.y)
		)


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


func _on_IconButton_pressed():
	_close_popup()


func _close_popup():
	emit_signal("close_popup")


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
