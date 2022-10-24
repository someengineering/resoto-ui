class_name WidgetContainer
extends Control

signal moved_or_resized
signal duplicate_widget(widget_container)
signal config_pressed(widget_container)

const max_hint:= "Maximize widget"
const min_hint:= "Minimize widget"

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
onready var title_label := $PanelContainer/TitleLabel
onready var datetime_label := $PanelContainer/Title/DataTimeLabel
onready var delete_button := $PanelContainer/Title/DeleteButton
onready var config_button := $PanelContainer/Title/ConfigButton
onready var duplicate_button := $PanelContainer/Title/DuplicateButton
onready var maximize_button := $PanelContainer/Title/MaximizeButton
onready var query_warning := $QueryWarning
onready var widget_content := $MarginContainer


func _ready() -> void:
	Style.add($ResizeButtons, Style.c.LIGHT)
	Style.add($QueryWarning/BG, Style.c.BG2)
	Style.add_self($QueryWarning/VBox/PanelContainer, Style.c.BG)
	Style.add_self($PanelContainer, Style.c.BG)
	
	maximize_button.modulate.a = 0
	for i in $ResizeButtons.get_child_count():
		var button : BaseButton = resize_buttons.get_child(i)
		button.connect("button_up", self, "_on_resize_button_released")
		button.connect("button_down", self, "_on_resize_button_pressed", [i])
	
	set_process(false)


func set_grid_size(new_grid_size : Vector2) -> void:
		grid_size = new_grid_size
		emit_signal("moved_or_resized")


func set_widget(_widget : BaseWidget) -> void:
	widget_content.add_child(_widget)
	widget = _widget
	$PanelContainer/Title/ExportButton.visible = widget.has_method("get_csv")


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
	
	refresh_pos_and_size_on_grid()
	set_anchors()


func refresh_pos_and_size_on_grid():
	position_on_grid = (rect_position / grid_size).snapped(Vector2.ONE)
	size_on_grid = (rect_size / grid_size).snapped(Vector2.ONE)


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
		RESIZE_MODES.NONE:
			continue
		
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
	duplicate_button.visible = !locked
	maximize_button.visible = locked
	title_label.modulate.a = 0.1 if !locked else 1.0

func set_title(new_title : String) -> void:
	title = new_title
	title_label.text = title

func execute_query() -> void:
	widget_content.show()
	query_warning.hide()
	if widget.has_method("clear_series"):
		widget.clear_series()
	
	datetime_label.text = "Live"
	for datasource in data_sources:
		var attr := {}
		match datasource.type:
			DataSource.TYPES.TIME_SERIES:
				attr["interval"] = dashboard.step
				attr["from"] = dashboard.ts_start
				attr["to"] = dashboard.ts_end
				datetime_label.text = "Historic"
		datasource.make_query(dashboard.filters, attr)


func _on_DeleteButton_pressed() -> void:
	var message_text:= "Do you want to delete this widget%s?"
	if title != "":
		message_text = message_text % (": \"" + title + "\" ")
	else:
		message_text = message_text % ""
		
	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		"Delete Widget?",
		message_text,
		"Yes", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String):
	if _response == "left":
		queue_free()


func _on_ConfigButton_pressed() -> void:
	emit_signal("config_pressed", self)


func set_data_sources(new_data_sources : Array) -> void:
	if new_data_sources.empty():
		return
	
	if new_data_sources[0] is DataSource:
		data_sources = new_data_sources
		for ds in data_sources:
			if not ds.is_connected("query_status", self, "_on_data_source_query_status"):
				ds.connect("query_status", self, "_on_data_source_query_status")
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
		"widget_type" : widget.widget_type_id,
		"settings" : widget_settings,
		"title" : title,
		"color_controllers_data" : color_controllers_data
	}
	
	if position_on_grid == Vector2.ZERO and size_on_grid == Vector2.ZERO:
		refresh_pos_and_size_on_grid()
	
	var data : Dictionary = {
		"position:x" : position_on_grid.x,
		"position:y" : position_on_grid.y,
		"size:x" : size_on_grid.x,
		"size:y" : size_on_grid.y,
		"widget_data" : widget_data,
		"data_sources_data" : _data_sources_data,
	}
	return data


func get_widget_properties() -> Dictionary:
	var found_settings := false
	var properties := {}
	for property in widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			properties[property.name] = widget[property.name]
		elif property.name == "Widget Settings":
			 found_settings = true
	return properties


func set_data_sources_data(data : Array) -> void:
	data_sources.clear()
	for settings in data:
		var ds
		match int(settings["type"]):
			DataSource.TYPES.TIME_SERIES:
				ds = TimeSeriesDataSource.new()
			DataSource.TYPES.AGGREGATE_SEARCH:
				ds = AggregateSearchDataSource.new()
			DataSource.TYPES.SEARCH:
				ds = TextSearchDataSource.new()
			DataSource.TYPES.TWO_ENTRIES_AGGREGATE:
				ds = TwoEntryAggregateDataSource.new()
				
		for key in settings:
			ds.set(key, settings[key])
		ds.widget = widget
		ds.connect("query_status", self, "_on_data_source_query_status")
		data_sources.append(ds)


func get_data_sources_data() -> Array:
	var data : Array = []
	for data_source in data_sources:
		data.append(data_source.get_data())
	return data


onready var query_warning_title = $QueryWarning/VBox/PanelContainer/VBox/QueryStatusTitle
func _on_data_source_query_status(_type:int=0, _title:="Widget Error", _message:=""):
	if _type == OK:
		return
	query_warning_title.visible = _title != ""
	query_warning_title.text = _title
	$QueryWarning/VBox/PanelContainer.hint_tooltip = _title + "\n" + _message
	query_warning.get_node("VBox/PanelContainer").visible = size_on_grid.y >= 2
	query_warning.show()


func _on_MaximizeButton_toggled(button_pressed):
	if position_on_grid == Vector2.ZERO and size_on_grid == Vector2.ZERO:
		refresh_pos_and_size_on_grid()
	is_maximized = button_pressed
	maximize_button.hint_tooltip = min_hint if is_maximized else max_hint
	set_as_toplevel(button_pressed)
	resize_buttons.visible = not (is_maximized or is_locked)
	emit_signal("moved_or_resized")


func _on_WidgetContainer_moved_or_resized():  
	if is_maximized:
		maximize_button.modulate.a = 0.1
		rect_global_position = get_parent().get_parent().get_parent().rect_global_position
		rect_size = get_parent().get_parent().get_parent().rect_size
	else:
		rect_position = position_on_grid * grid_size
		rect_size = size_on_grid * grid_size
	
	if query_warning:
		$QueryWarning/VBox/PanelContainer/VBox/QueryStatusTitle.visible = (size_on_grid.y >= 2 and size_on_grid.x >= 2) or is_maximized


func _on_ExportButton_pressed():
	JavaScript.download_buffer(widget.get_csv().to_utf8(), "%s %s.csv" % [title, Time.get_datetime_string_from_system()])


func _on_DuplicateButton_pressed():
	emit_signal("duplicate_widget", self)


func _on_PanelContainer_mouse_entered():
	maximize_button.modulate.a = 1.0 if !is_maximized else 0.1


func _on_PanelContainer_mouse_exited():
	if not is_maximized:
		maximize_button.modulate.a = 0.0


func _on_WidgetContainer_tree_exiting():
	for data_source in data_sources:
		data_source.queue_free()
