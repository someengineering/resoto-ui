extends Control

enum RESIZE_MODES {
	MOVE,
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MID_LEFT,
	MID_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
	NONE
	}

var resize_mode = RESIZE_MODES.NONE
var grid_size : Vector2 = Vector2(100, 100)
var grid_margin : Vector2 = Vector2(5, 5)
var last_pressed_position : Vector2
var press_offset : Vector2
var limits : Dictionary = {}
var dashboard : Control

var check_rect : Rect2

onready var parent_reference : ReferenceRect
onready var resize_buttons := $ResizeButtons
onready var resize_tween := $ResizeTween
onready var last_good_position : Vector2
onready var last_good_size : Vector2


func _ready() -> void:
	for i in resize_buttons.get_child_count():
		var button : BaseButton = resize_buttons.get_child(i)
		button.connect("button_up", self, "_on_resize_button_released")
		button.connect("button_down", self, "_on_resize_button_pressed", [i])
	
	set_process(false)


func _on_resize_button_released() -> void:
	
	set_process(false)
	if resize_tween.is_active():
		yield(resize_tween,"tween_all_completed")
	parent_reference.visible = false
	resize_tween.interpolate_property(self, "rect_size", rect_size, parent_reference.rect_size, 0.2)
	resize_tween.interpolate_property(self, "rect_position", rect_position, parent_reference.rect_position, 0.2)
	resize_tween.start()
	
	resize_mode = RESIZE_MODES.NONE
	yield(resize_tween, "tween_all_completed")
	set_anchors()


func set_anchors():
	var dashboard_size = dashboard.rect_size
	margin_left = 0
	margin_right = 0
	anchor_left = (parent_reference.rect_position.x) / dashboard_size.x
	anchor_right = (parent_reference.rect_position + parent_reference.rect_size).x / dashboard_size.x

func _on_resize_button_pressed( mode : int) -> void:
	limits = get_limits()
	parent_reference.visible = true
	parent_reference.rect_global_position = rect_global_position
	parent_reference.rect_size = rect_size
	check_rect = parent_reference.get_rect()
	last_pressed_position = dashboard.get_local_mouse_position().snapped(grid_size)
	last_good_position = rect_global_position
	last_good_size = rect_size
	resize_mode = mode
	press_offset = last_pressed_position - rect_position
	set_process(true)


func _process(_delta : float) -> void:
	var global_mouse_position = get_global_mouse_position()
	var local_mouse_position = dashboard.get_local_mouse_position()
	var new_position : Vector2 = local_mouse_position.snapped(grid_size) 
	
	match resize_mode:
		RESIZE_MODES.TOP_LEFT:
			var right_bot_corner = parent_reference.rect_position + parent_reference.rect_size - grid_size
			var prev_rect_position : Vector2 = rect_position
			rect_position.x = clamp(local_mouse_position.x, limits.left, right_bot_corner.x)
			rect_position.y = clamp(local_mouse_position.y, limits.top, right_bot_corner.y)
			rect_size += prev_rect_position - rect_position
			
			new_position.x = clamp(new_position.x, limits.left, right_bot_corner.x)
			new_position.y = clamp(new_position.y, limits.top, right_bot_corner.y)
			
			if new_position != last_pressed_position:
				check_rect.position = new_position
				check_rect.size = parent_reference.rect_size - (new_position - parent_reference.rect_position)
				

		RESIZE_MODES.BOTTOM_RIGHT:
			var max_right_corner = parent_reference.rect_position + grid_size
			
			rect_size.x = clamp(local_mouse_position.x, max_right_corner.x, limits.right) - rect_position.x
			rect_size.y = clamp(local_mouse_position.y, max_right_corner.y, limits.bottom) - rect_position.y
			
			new_position.x = clamp(new_position.x, max_right_corner.x, limits.right)
			new_position.y = clamp(new_position.y, max_right_corner.y, limits.bottom)
			
			if new_position != last_pressed_position:
				check_rect.size = new_position - check_rect.position
		
			
		RESIZE_MODES.TOP_RIGHT:
			var min_right = parent_reference.rect_position.x + grid_size.x
			var max_top = parent_reference.rect_position.y + parent_reference.rect_size.y  - grid_size.y
			var prev_rect_position : Vector2 = rect_position
			
			rect_position.y = clamp(local_mouse_position.y, limits.top, max_top)
			rect_size.x = clamp(local_mouse_position.x, min_right, limits.right) - rect_position.x
			rect_size.y += prev_rect_position.y - rect_position.y
			
			new_position.x = clamp(new_position.x, min_right, limits.right)
			new_position.y = clamp(new_position.y, limits.top, max_top)
			
			if new_position != last_pressed_position:
				check_rect.position.y = new_position.y
				check_rect.size = Vector2(new_position.x - parent_reference.rect_position.x, parent_reference.rect_size.y - (new_position.y - parent_reference.rect_position.y))

				
		RESIZE_MODES.BOTTOM_LEFT:
			var max_left = parent_reference.rect_position.x + parent_reference.rect_size.x - grid_size.x 
			var min_bottom = parent_reference.rect_position.y + grid_size.y
			var prev_rect_position : Vector2 = rect_position
			
			rect_position.x = clamp(local_mouse_position.x, limits.left, max_left)
			rect_size.x += prev_rect_position.x - rect_position.x
			rect_size.y = clamp(local_mouse_position.y, min_bottom, limits.bottom) - rect_position.y
			
			new_position.x = clamp(new_position.x, limits.left, max_left)
			new_position.y = clamp(new_position.y, min_bottom, limits.bottom)
			
			if new_position != last_pressed_position:
				check_rect.position.x = new_position.x
				check_rect.size = Vector2(parent_reference.rect_size.x - (new_position.x - parent_reference.rect_position.x), new_position.y - parent_reference.rect_position.y)
				
		RESIZE_MODES.BOTTOM_CENTER:
			var min_bottom = parent_reference.rect_position.y  + grid_size.y
			
			rect_size.y = clamp(local_mouse_position.y, min_bottom, limits.bottom) - rect_position.y
			new_position.y = clamp(new_position.y, min_bottom, limits.bottom)
			
			if new_position != last_pressed_position:
				check_rect.size.y = new_position.y - parent_reference.rect_position.y
				
		RESIZE_MODES.TOP_CENTER:
			var max_top = parent_reference.rect_position.y + parent_reference.rect_size.y - grid_size.y 
			var prev_rect_position = rect_position
			
			rect_position.y = clamp(local_mouse_position.y, limits.top, max_top)
			rect_size.y += prev_rect_position.y - rect_position.y
			new_position.y = clamp(new_position.y, limits.top, max_top)
			
			if new_position.y != last_pressed_position.y :
				check_rect.position.y = new_position.y
				check_rect.size.y = parent_reference.rect_size.y - (new_position - parent_reference.rect_position).y
				
		RESIZE_MODES.MID_LEFT:
			var max_left = parent_reference.rect_position.x + parent_reference.rect_size.x - grid_size.x 
			var prev_rect_position = rect_position
			rect_position.x = clamp(local_mouse_position.x, limits.left, max_left)
			rect_size.x += prev_rect_position.x - rect_position.x
			new_position.x = clamp(new_position.x, limits.left, max_left)
			
			if new_position.x != last_pressed_position.x:
				check_rect.position.x = new_position.x
				check_rect.size.x = parent_reference.rect_size.x - (new_position - parent_reference.rect_position).x
			
		RESIZE_MODES.MID_RIGHT:
			var min_right = parent_reference.rect_position.x + grid_size.x 
			new_position.x = clamp(new_position.x, min_right, limits.right)
			rect_size.x = clamp(local_mouse_position.x, min_right, limits.right) - rect_position.x
			
			if new_position.x != last_pressed_position.x:
				check_rect.size.x = new_position.x - parent_reference.rect_position.x
				
		RESIZE_MODES.MOVE:
			rect_position = local_mouse_position - press_offset
			rect_position.x = clamp(rect_position.x , 0, dashboard.rect_size.x - rect_size.x)
			rect_position.y = max(0, rect_position.y)
			
			new_position = rect_position.snapped(grid_size)
			var test_rect = parent_reference.get_rect()
			test_rect.position = new_position
			test_rect = test_rect.grow_individual(-1,-1,-1,-1)
			test_rect = find_rect_intersection(test_rect)
			
			if test_rect != null:
				return
			
			if new_position != last_pressed_position:
				check_rect.position = new_position
			
	if last_pressed_position != new_position:
		animate_reference_rect()
		limits = get_limits()
		
	last_pressed_position = new_position
	
func animate_reference_rect():
	resize_tween.interpolate_property(parent_reference, "rect_position", parent_reference.rect_position, check_rect.position, 0.2)
	resize_tween.interpolate_property(parent_reference, "rect_size", parent_reference.rect_size, check_rect.size, 0.2)
	resize_tween.start()
			
func get_limits() -> Dictionary:
	var limits := {
		"left" : 0,
		"right" : dashboard.rect_size.x,
		"top" : 0,
		"bottom" : INF
	}

	var rect = find_next_rect(Vector2.LEFT)
	if rect != null:
		limits.left = rect.end.x
		
	rect = find_next_rect(Vector2.UP)
	if rect != null:
		limits.top = rect.end.y
		
	rect = find_next_rect(Vector2.RIGHT)
	if rect != null:
		limits.right = rect.position.x
		
	rect = find_next_rect(Vector2.DOWN)
	if rect != null:
		limits.bottom = rect.position.y
	return limits

func segment_overlap(a_min,a_max,b_min,b_max):
	return ( (a_min >= b_min and a_min <= b_max) or 
		( a_max <= b_max and a_max >= b_min ) or (a_min <= b_min and a_max >= b_max) )
	
func find_next_rect(direction : Vector2, N=10):
	var rect : Rect2 = check_rect
	direction *= grid_size
	for i in N:
		rect = rect.grow_individual(-direction.x if direction.x < 0 else 0,
							-direction.y if direction.y < 0 else 0,
							direction.x if direction.x > 0 else 0,
							direction.y if direction.y > 0 else 0)
		var other_rect = find_rect_intersection(rect)
		if other_rect != null:
			return other_rect
			
	return null

func find_rect_intersection(rect : Rect2 = parent_reference.get_global_rect()):
	var all_widgets : Array = dashboard.widgets.get_children()
	for widget in all_widgets:
		if widget == self:
			continue
		var other_rect : Rect2 = widget.parent_reference.get_rect()

		if other_rect.intersects(rect):
			return other_rect
	return null
	

func _on_ResizeTween_tween_all_completed():
	limits = get_limits()
