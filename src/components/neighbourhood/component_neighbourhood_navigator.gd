extends Node2D

const MIN_ZOOM : float = 0.005
const MAX_ZOOM : float = 1.5

signal change_zoom

var zoom_level:float		= 1.0
var drag_stopped:bool		= false
var is_dragging:bool		= false
var drag_position:Vector2	= Vector2.ZERO

onready var content = $Content
onready var drag_hint = $MouseDragHint
onready var graph : Control = get_parent()
onready var zoom_tween : Tween = $ZoomTween


func _ready():
	drag_hint.set_as_toplevel(true)


func _process(_delta):
	var _is_dragging : bool = (
		Input.is_mouse_button_pressed(1)
		and graph.get_global_rect().has_point(get_global_mouse_position())
		and is_visible_in_tree()) 
	dragging(_is_dragging)


func _input(event):
	if event is InputEventMouse and not graph.get_global_rect().has_point(event.global_position):
		return
	var zoom_amount = 0.05 if _g.os != "MacOS" else -0.05
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom(zoom_amount, event.position)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom(-zoom_amount, event.position)


func reset_position():
	content.position = Vector2.ZERO


var zoom_reset_position := 1.0
func set_zoom(new_zoom_level:float):
	zoom_level = clamp(new_zoom_level, MIN_ZOOM, MAX_ZOOM)
	zoom_reset_position = zoom_level
	emit_signal("change_zoom", zoom_level)
	content.scale = Vector2.ONE * zoom_level


func zoom(_change:float, _pos:Vector2):
	_change *= zoom_level*2.0
	var new_zoom_level = clamp(zoom_level+_change, MIN_ZOOM, MAX_ZOOM)
	if new_zoom_level == zoom_level:
		return
	emit_signal("change_zoom", new_zoom_level)
	var parent_rect : Rect2 = graph.get_global_rect()
	var local_event_pos = (content.position - _pos + parent_rect.position) * -sign(_change) / new_zoom_level
	var new_pos = content.position - local_event_pos * abs(_change)
	
	if zoom_tween.is_active():
		zoom_tween.seek(0.2)
		zoom_tween.remove_all()
	
	zoom_tween.interpolate_property(content, "scale", content.scale, Vector2.ONE * new_zoom_level, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	zoom_tween.interpolate_property(content, "position", content.position, new_pos, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	zoom_tween.interpolate_method(self, "change_zoom_level", zoom_level, new_zoom_level, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	zoom_tween.start()


func change_zoom_level(_zoom_level:float):
	zoom_level = _zoom_level


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


func _on_ButtonZoomPlus_pressed():
	zoom(0.05, graph.get_global_rect().get_center())


func _on_ButtonZoomMinus_pressed():
	zoom(-0.05, graph.get_global_rect().get_center())


func _on_ButtonZoomCenter_pressed():
	set_zoom(zoom_reset_position)
