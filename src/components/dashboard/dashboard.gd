extends Control

signal need_to_resize(y)
signal widget_scrolling

export (NodePath) var scrollcontainer_path : NodePath = ""

export var x_grid_ratio := 10.0 
export var y_grid_size := 100.0 
export var grid_margin := Vector2(5,5)

var locked := true
var initial_grid_set:= true
var dashboard_container:DashboardContainer = null
var is_ready := false
var ts_start : int
var ts_end : int
var step : int
var widget_reveal_timer:= Timer.new()
var appear_tween:= Tween.new()
var scroll_container:ScrollContainer

var filters : Dictionary = {
	"cloud" : "",
	"region" : "",
	"account" : ""
}

var remap_old_data:= {
	"res://components/widgets/TableWidget.tscn":	"Table",
	"res://components/widgets/Indicator.tscn":		"Indicator",
	"res://components/widgets/Chart.tscn":			"Chart",
	"res://components/widgets/HeatMap.tscn":		"Heatmap",
}

onready var widgets : Control = $Widgets
onready var grid_background : ColorRect = $Grid
onready var _x_grid_size := rect_size.x / x_grid_ratio
onready var widget_container_scene := preload("res://components/dashboard/container/widget_container.tscn")


func _ready():
	scroll_container = get_node(scrollcontainer_path)
	add_child(widget_reveal_timer)
	widget_reveal_timer.wait_time = 0.1
	widget_reveal_timer.one_shot = true
	add_child(appear_tween)
	is_ready = true
	$Grid.connect("resized", self, "_on_Grid_resized")


func add_widget(widget_data : Dictionary, _show_after_creation:=false) -> WidgetContainer:
	var grid_size : Vector2 = Vector2(_x_grid_size, y_grid_size)
	var container = widget_container_scene.instance()
	container.hide()
	container.name = "WidgetContainer"
	container.dashboard = self
	container.grid_size = grid_size
	container.rect_size = 2*grid_size
	widgets.call_deferred("add_child", container)
	
	var empty_slot = find_empty_slot(container.get_rect())
	container.rect_position = empty_slot.snapped(grid_size) 
	
	var reference = ReferenceRect.new()
	container.parent_reference = reference
	$References.add_child(reference)
	
	container.connect("moved_or_resized", self, "_on_widget_moved_or_resized")
	
	var widget : BaseWidget
	
	if widget_data.scene is BaseWidget:
		widget = widget_data.scene
	elif widget_data.scene is String:
		if not widget_data.has("widget_type"):
			widget_data["widget_type"] = remap_old_data[widget_data.scene]
		widget = dashboard_container.WidgetScenes[widget_data.widget_type].instance()
	
	if widget.has_signal("scrolling"):
		widget.connect("scrolling", self, "_on_widget_scrolling")
	
	container.call_deferred("set_widget", widget)
	container.call_deferred("set_data_sources", widget_data.data_sources)
	container.set_deferred("title", widget_data.title)
	container.call_deferred("lock", locked)
	
	if widget_data.has("settings"):
		for key in widget_data.settings:
			if "color" in key and not widget_data.settings[key] is Color:
				# asume it was passed as string
				widget_data.settings[key] = str2var(widget_data.settings[key])
			widget.set(key, widget_data.settings[key])
	
	if widget_data.has("color_controllers_data"):
		widget.color_controllers_data = widget_data.color_controllers_data
	
	container.connect("config_pressed", owner, "_on_WidgetContainer_config_pressed")
	container.connect("duplicate_widget", owner, "_on_WidgetContainer_duplicate_pressed")
	
	if not container.is_inside_tree():
		yield(container, "tree_entered")
	
	reference.rect_global_position = container.rect_global_position
	reference.rect_size = container.rect_size
	
	reference.mouse_filter = MOUSE_FILTER_IGNORE
	reference.border_color = Style.col_map[Style.c.NORMAL]
	reference.border_width = 2
	reference.editor_only = false
	reference.visible = false
	
	if _show_after_creation:
		widget_reveal_timer.connect("timeout", self, "reveal_widget", [container], CONNECT_ONESHOT)
		widget_reveal_timer.start()
		
	if empty_slot.y + container.rect_size.y > get_parent().rect_size.y:
		_on_widget_moved_or_resized()
	
	return container


func reveal_widget(_widget_container:WidgetContainer):
	_widget_container.modulate.a = 0.0
	appear_tween.interpolate_property(_widget_container, "modulate:a", 0, 1, 0.8, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_widget_container.show()
	appear_tween.start()


func lock(_locked : bool) -> void:
	locked = _locked
	grid_background.visible = !locked
	
	for widget in widgets.get_children():
		widget.lock(locked)


func _on_Grid_resized() -> void:
	var new_x_size = rect_size.x / x_grid_ratio
	$Grid.material.set_shader_param("dashboard_size", rect_size)
	if not is_ready or is_equal_approx(new_x_size, _x_grid_size):
		return
		
	_x_grid_size = new_x_size
	var grid_size := Vector2(_x_grid_size, y_grid_size)
	$Grid.material.set_shader_param("grid_size", grid_size)
	$ResizeTimer.start()


func _on_ResizeTimer_timeout():
	var grid_size := Vector2(_x_grid_size, y_grid_size)
	
	var w_delay:= 0.3
	for widget in $Widgets.get_children():
		widget.grid_size = grid_size
		widget.parent_reference.rect_global_position = widget.position_on_grid * grid_size + rect_global_position
		widget.parent_reference.rect_size = widget.size_on_grid * grid_size
		widget.call_deferred("set_anchors")
		if initial_grid_set:
			widget.modulate.a = 0.0
			appear_tween.interpolate_property(widget, "modulate:a", 0, 1, 1.3, Tween.TRANS_EXPO, Tween.EASE_OUT, w_delay)
			w_delay += 0.1
			widget.show()
	appear_tween.start()
	initial_grid_set = false


func find_rect_intersection(rect : Rect2, exclude_widgets := []):
	var all_widgets : Array = widgets.get_children()

	for widget in all_widgets:
		if widget in exclude_widgets:
			continue
		var other_rect : Rect2 = widget.parent_reference.get_rect()

		if other_rect.intersects(rect):
			return other_rect
	return null


func find_empty_slot(rect : Rect2) -> Vector2:
	var position = null
	var j : int = 0
	rect = rect.grow_individual(-1,-1,-1,-1)
	while true:
		for i in (x_grid_ratio):
			rect.position = Vector2(i * _x_grid_size, j * y_grid_size)
			if rect.position.x + rect.size.x > rect_size.x:
				continue
			if find_rect_intersection(rect) == null:
				position = rect.position
				break
		if position != null:
			break
		j += 1
	return position


func refresh(from : int = ts_start, to : int = ts_end, interval : int = step) -> void:
	ts_start = from
	ts_end = to
	step = interval
	for widget in widgets.get_children():
		widget.execute_query()


func _on_widget_moved_or_resized():
	var max_y = -INF
	for widget in widgets.get_children():
		if widget.is_maximized:
			max_y = get_parent().rect_size.y
			break
		if widget.rect_size.y + widget.rect_position.y > max_y:
			max_y = widget.rect_size.y + widget.rect_position.y
	
	emit_signal("need_to_resize", max_y)
	
	
func _on_widget_scrolling():
	emit_signal("widget_scrolling")
