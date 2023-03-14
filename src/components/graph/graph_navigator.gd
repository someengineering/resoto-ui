extends Node2D

signal change_zoom

var extents:Rect2
var padding:float			= 20.0
var zoom_level:float		= 1.0
var drag_stopped:bool		= false
var is_dragging:bool		= false
var drag_position:Vector2	= Vector2.ZERO

onready var content = $Content
onready var drag_hint = $MouseDragHint

func _ready():
	drag_hint.set_as_toplevel(true)


func update_extents():
	var min_pos:Vector2 = Vector2(1000000, 1000000)
	var max_pos:Vector2 = Vector2(-1000000, -1000000)
	for c in content.get_children():
		# find smallest position on all elements
		if c.position.x < min_pos.x:
			min_pos.x = c.position.x
		if c.position.y < min_pos.y:
			min_pos.y = c.position.y
		
		# find largest position on all elements
		if c.position.x > max_pos.x:
			max_pos.x = c.position.x
		if c.position.y > max_pos.y:
			max_pos.y = c.position.y
	
	extents.position = min_pos - Vector2(padding, padding)
	extents.end = max_pos + Vector2(padding, padding)


func _process(delta):
	dragging(Input.is_mouse_button_pressed(1))


func _input(event):
	var zoom_amount = 0.05 if _g.platform != "MacOS" else -0.05
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom(zoom_amount)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom(-zoom_amount)


func reset_position():
	content.position = Vector2.ZERO


func zoom(_change:float):
	var new_zoom_level = clamp(zoom_level+_change, 0.02, 1.5)
	if new_zoom_level == zoom_level:
		return
	zoom_level = new_zoom_level
	emit_signal("change_zoom", zoom_level)
	var mouse_pos_at_zoom_event = content.position - get_global_mouse_position()
	if _change > 0:
		mouse_pos_at_zoom_event *= -1
	content.scale = Vector2.ONE * zoom_level
	content.position -= (mouse_pos_at_zoom_event / zoom_level) * abs(_change)


func dragging(_is_dragging:bool):
	if is_dragging != _is_dragging:
		is_dragging = _is_dragging
		drag_hint.visible = is_dragging
		if is_dragging:
			drag_position = content.position - get_global_mouse_position()
	
	if is_dragging:
		content.position = drag_position + get_global_mouse_position()
		drag_stopped = false
		drag_hint.global_position = get_global_mouse_position()
	elif not drag_stopped:
		drag_stopped = true
