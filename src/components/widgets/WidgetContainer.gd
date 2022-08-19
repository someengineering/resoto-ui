class_name WidgetContainer
extends Control

signal moved_or_resized
signal config_pressed(widget_container)

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
var grid_size : Vector2 = Vector2(100, 100) setget set_grid_size
var grid_margin : Vector2 = Vector2(5, 5)
var last_pressed_position : Vector2
var press_offset : Vector2
var limits : Dictionary = {}
var dashboard : Control
var widget : BaseWidget

var position_on_grid : Vector2
var size_on_grid : Vector2

var check_rect : Rect2
export var title : String = "" setget set_title
var data_sources : Array setget set_data_sources

var is_locked : bool = true
var is_maximized : bool = false

# just for load
var data_sources_data : Array setget set_data_sources_data, get_data_sources_data

onready var parent_reference : ReferenceRect
onready var resize_buttons := $ResizeButtons
onready var resize_tween := $ResizeTween
onready var last_good_position : Vector2
onready var last_good_size : Vector2
onready var title_label := $PanelContainer/Title/TitleLabel
onready var delete_button := $PanelContainer/Title/DeleteButton
onready var config_button := $PanelContainer/Title/ConfigButton
onready var maximize_button := $PanelContainer/Title/MaximizeButton


func _ready() -> void:
	for i in $ResizeButtons.get_child_count():
		var button : BaseButton = resize_buttons.get_child(i)
		button.connect("button_up", self, "_on_resize_button_released")
		button.connect("button_down", self, "_on_resize_button_pressed", [i])
	
	set_process(false)


func set_grid_size(new_grid_size : Vector2) -> void:
		grid_size = new_grid_size
		
		emit_signal("moved_or_resized")


func set_widget(_widget : BaseWidget) -> void:
	$MarginContainer.add_child(_widget)
	widget = _widget

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
	
	position_on_grid = (rect_position / grid_size).snapped(Vector2.ONE)
	size_on_grid = (rect_size / grid_size).snapped(Vector2.ONE)
	
	set_anchors()

func set_anchors() -> void:
	var dashboard_size = dashboard.rect_size
	rect_size = rect_size.snapped(grid_size)
	rect_position = rect_position.snapped(grid_size)
	margin_left = 0
	margin_right = 0
	anchor_left = (parent_reference.rect_position.x) / dashboard_size.x
	anchor_right = (parent_reference.rect_position + parent_reference.rect_size).x / dashboard_size.x
	emit_signal("moved_or_resized")

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
			test_rect = dashboard.find_rect_intersection(test_rect, [self])
			
			if test_rect != null:
				return
			
			if new_position != last_pressed_position:
				check_rect.position = new_position
			
	if last_pressed_position != new_position:
		animate_reference_rect()
		limits = get_limits()
		
	last_pressed_position = new_position
	
func animate_reference_rect() -> void:
	resize_tween.interpolate_property(parent_reference, "rect_position", parent_reference.rect_position, check_rect.position, 0.2)
	resize_tween.interpolate_property(parent_reference, "rect_size", parent_reference.rect_size, check_rect.size, 0.2)
	resize_tween.start()
			
func get_limits() -> Dictionary:
	var _limits := {
		"left" : 0,
		"right" : dashboard.rect_size.x,
		"top" : 0,
		"bottom" : INF
	}

	var rect = find_next_rect(Vector2.LEFT)
	if rect != null:
		_limits.left = rect.end.x
		
	rect = find_next_rect(Vector2.UP)
	if rect != null:
		_limits.top = rect.end.y
		
	rect = find_next_rect(Vector2.RIGHT)
	if rect != null:
		_limits.right = rect.position.x
		
	rect = find_next_rect(Vector2.DOWN)
	if rect != null:
		_limits.bottom = rect.position.y
		
	return _limits
	
func find_next_rect(direction : Vector2, N=10):
	var rect : Rect2 = check_rect
	direction *= grid_size
	for i in N:
		rect = rect.grow_individual(-direction.x if direction.x < 0.0 else 0.0,
							-direction.y if direction.y < 0.0 else 0.0,
							direction.x if direction.x > 0.0 else 0.0,
							direction.y if direction.y > 0.0 else 0.0)
		var other_rect = dashboard.find_rect_intersection(rect, [self])
		if other_rect != null:
			return other_rect
			
	return null
	

func _on_ResizeTween_tween_all_completed() -> void:
	limits = get_limits()

func lock(locked : bool) -> void:
	is_locked = locked
	resize_buttons.visible = not (is_locked or is_maximized)
	delete_button.visible = !locked
	config_button.visible = !locked

func set_title(new_title : String) -> void:
	title = new_title
	$PanelContainer/Title/TitleLabel.text = title

func execute_query() -> void:
	if widget.has_method("clear_series"):
		widget.clear_series()
	for datasource in data_sources:
		datasource.make_query(dashboard.ts_start, dashboard.ts_end, dashboard.step, dashboard.filters)


func _on_DeleteButton_pressed() -> void:
	queue_free()


func _on_ConfigButton_pressed() -> void:
	emit_signal("config_pressed", self)

func set_data_sources(new_data_sources : Array) -> void:
	if new_data_sources.size() > 0:
		if new_data_sources[0] is DataSource:
			data_sources = new_data_sources
		else:
			set_data_sources_data(new_data_sources)

func get_data() -> Dictionary:
	var widget_settings : Dictionary = {}
	for setting in get_widget_properties():
		if "color" in setting:
			widget_settings[setting] = var2str(widget[setting])
		else:
			widget_settings[setting] = widget[setting]
		
	var _data_sources_data : Array = []
	for data_source in data_sources:
		_data_sources_data.append(data_source.get_data())
		
	var color_controllers_data : Array = []
	
	for child in widget.get_children():
		if child is ColorController:
			color_controllers_data.append(
				var2str(child.conditions)
			)
		
	var widget_data : Dictionary = {
		"scene" : widget.filename,
		"settings" : widget_settings,
		"title" : title,
		"color_controllers_data" : color_controllers_data
	}
	
	var data : Dictionary = {
		"position:x" : position_on_grid.x,
		"position:y" : position_on_grid.y,
		"size:x" : size_on_grid.x,
		"size:y" : size_on_grid.y,
		"widget_data" : widget_data,
		"data_sources_data" : _data_sources_data,
	}
	print(grid_size)
	return data
	
func get_widget_properties() -> Dictionary:
	var found_settings := false
	var properties := {}
	for property in widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			properties[property.name] = widget[property.name]
			print(property.name)
		elif property.name == "Widget Settings":
			 found_settings = true
	return properties

func set_data_sources_data(data : Array) -> void:
	data_sources.clear()
	for settings in data:
		var ds = DataSource.new()
		for key in settings:
			ds.set(key, settings[key])
		ds.widget = widget
		data_sources.append(ds)
	
func get_data_sources_data() -> Array:
	var data : Array = []
	for data_source in data_sources:
		data.append(data_source.get_data())
	return data


func _on_MaximizeButton_toggled(button_pressed):
	is_maximized = button_pressed
	set_as_toplevel(button_pressed)
	resize_buttons.visible = not (is_maximized or is_locked)
	emit_signal("moved_or_resized")


func _on_WidgetContainer_moved_or_resized():  
	if is_maximized:
		rect_global_position = get_parent().get_parent().get_parent().rect_global_position
		rect_size = get_parent().get_parent().get_parent().rect_size
	else:
		rect_position = position_on_grid * grid_size
		rect_size = size_on_grid * grid_size
