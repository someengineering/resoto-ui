tool
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

onready var parent : Control = get_parent()
onready var resize_buttons := $ResizeButtons
onready var resize_tween := $ResizeTween

func _ready() -> void:
	for i in resize_buttons.get_child_count():
		var button : BaseButton = resize_buttons.get_child(i)
		button.connect("button_up", self, "_on_resize_button_released")
		button.connect("button_down", self, "_on_resize_button_pressed", [i])
		
	set_process(false)

func _get_configuration_warning() -> String:
	if not parent is Control:
		return "Widget Resizer needs a Control node as parent."
	return ""


func _on_resize_button_released() -> void:
	resize_mode = RESIZE_MODES.NONE
	set_process(false)


func _on_resize_button_pressed( mode : int) -> void:
	last_pressed_position = get_global_mouse_position()
	resize_mode = mode
	press_offset = last_pressed_position - parent.rect_position
	set_process(true)


func _process(_delta : float) -> void:
	match resize_mode:
		RESIZE_MODES.TOP_LEFT:
			var min_left_corner = parent.rect_position + parent.rect_size + 2*grid_margin - grid_size
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) + grid_margin
			new_position.x = min(new_position.x, min_left_corner.x)
			new_position.y = min(new_position.y, min_left_corner.y)
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_position", parent.rect_position, new_position, 0.2)
				resize_tween.interpolate_property(parent, "rect_size", parent.rect_size, parent.rect_size - (new_position - parent.rect_position), 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position
			
		RESIZE_MODES.BOTTOM_RIGHT:
			var max_right_corner = parent.rect_position + grid_size - 2*grid_margin
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) - grid_margin
			new_position.x = max(new_position.x, max_right_corner.x)
			new_position.y = max(new_position.y, max_right_corner.y)
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_size", parent.rect_size, new_position - parent.rect_position, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position

		RESIZE_MODES.TOP_RIGHT:
			var max_right = parent.rect_position.x + grid_size.x - 2*grid_margin.x
			var min_top = parent.rect_position.y + parent.rect_size.y + 2* grid_margin.y - grid_size.y
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) + grid_margin * Vector2(-1,1)
			new_position.x = max(new_position.x, max_right)
			new_position.y = min(new_position.y, min_top)
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_position:y", parent.rect_position.y, new_position.y, 0.2)
				resize_tween.interpolate_property(parent, "rect_size:y", parent.rect_size.y, parent.rect_size.y - (new_position.y - parent.rect_position.y), 0.2)
				resize_tween.interpolate_property(parent, "rect_size:x", parent.rect_size.x, new_position.x - parent.rect_position.x, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position
			
		RESIZE_MODES.BOTTOM_LEFT:
			var min_left = parent.rect_position.x + parent.rect_size.x - grid_size.x + 2*grid_margin.x
			var max_bottom = parent.rect_position.y - 2* grid_margin.y + grid_size.y
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) + grid_margin * Vector2(1,-1)
			new_position.x = min(new_position.x, min_left)
			new_position.y = max(new_position.y, max_bottom)
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_position:x", parent.rect_position.x, new_position.x, 0.2)
				resize_tween.interpolate_property(parent, "rect_size:x", parent.rect_size.x, parent.rect_size.x - (new_position.x - parent.rect_position.x), 0.2)
				resize_tween.interpolate_property(parent, "rect_size:y", parent.rect_size.y, new_position.y - parent.rect_position.y, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position 
			
		RESIZE_MODES.BOTTOM_CENTER:
			var max_bottom = parent.rect_position.y - 2*grid_margin.y + grid_size.y
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) - grid_margin 
			new_position.y = max(new_position.y, max_bottom)
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_size:y", parent.rect_size.y, new_position.y - parent.rect_position.y, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position 
			
		RESIZE_MODES.TOP_CENTER:
			var min_top = parent.rect_position.y + parent.rect_size.y - grid_size.y + 2*grid_margin.y
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) + grid_margin
			new_position.y = min(new_position.y, min_top)
			
			if new_position.y != last_pressed_position.y :
				resize_tween.interpolate_property(parent, "rect_position:y", parent.rect_position.y, new_position.y, 0.2)
				resize_tween.interpolate_property(parent, "rect_size:y", parent.rect_size.y, parent.rect_size.y - (new_position - parent.rect_position).y, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position 
			
		RESIZE_MODES.MID_LEFT:
			var max_left = parent.rect_position.x + parent.rect_size.x - grid_size.x + 2*grid_margin.x
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) + grid_margin
			new_position.x = min(new_position.x, max_left)
			
			if new_position.x != last_pressed_position.x:
				resize_tween.interpolate_property(parent, "rect_position:x", parent.rect_position.x, new_position.x, 0.2)
				resize_tween.interpolate_property(parent, "rect_size:x", parent.rect_size.x, parent.rect_size.x - (new_position - parent.rect_position).x, 0.2)
				resize_tween.start()
		
			last_pressed_position = new_position
			
		RESIZE_MODES.MID_RIGHT:
			var min_right = parent.rect_position.x + grid_size.x - 2*grid_margin.x
			var new_position : Vector2 = get_global_mouse_position().snapped(grid_size) - grid_margin
			new_position.x = max(new_position.x, min_right)
			
			if new_position.x != last_pressed_position.x:
				resize_tween.interpolate_property(parent, "rect_size:x", parent.rect_size.x, new_position.x - parent.rect_position.x, 0.2)
				resize_tween.start()
				
			last_pressed_position = new_position 
				
		RESIZE_MODES.MOVE:
			var new_position : Vector2 = (get_global_mouse_position()-press_offset).snapped(grid_size) + grid_margin
			
			if new_position != last_pressed_position:
				resize_tween.interpolate_property(parent, "rect_position", parent.rect_position, new_position, 0.2)
				resize_tween.start()
			
			last_pressed_position = new_position
