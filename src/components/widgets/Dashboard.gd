extends Control

onready var widgets : Control = $Widgets
onready var grid_background : ColorRect = $Grid

export var x_grid_ratio := 10.0 
export var y_grid_size := 100.0 
export var grid_margin := Vector2(5,5)

onready var _x_grid_size := rect_size.x / x_grid_ratio
onready var widget_resizer_scene := preload("res://components/widgets/WidgetResizer.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		add_widget()

func add_widget():
	var grid_size : Vector2 = Vector2(_x_grid_size, y_grid_size)
	var widget = ColorRect.new()
	widget.rect_size = Vector2(256,256)
	widgets.add_child(widget)
	var resizer = widget_resizer_scene.instance()
	resizer.name = "WidgetResizer"
	resizer.dashboard = self
	widget.call_deferred("add_child", resizer)
	resizer.grid_size = grid_size
	widget.rect_position = widget.rect_position.snapped(grid_size) + grid_margin
	widget.rect_size = widget.rect_size.snapped(grid_size) - 2*grid_margin
	var reference = ReferenceRect.new()
	resizer.parent_reference = reference
	$References.add_child(reference)
	
	yield(VisualServer,"frame_post_draw")
	
	reference.rect_global_position = resizer.rect_global_position
	reference.rect_size = resizer.rect_size
	
	reference.mouse_filter = MOUSE_FILTER_IGNORE
	reference.border_color = Color(0.662745, 0.568627, 0.792157)
	reference.editor_only = false
	reference.visible = false
	
	resizer.set_anchors()
	
		
func _on_Grid_resized() -> void:
	_x_grid_size = rect_size.x / x_grid_ratio

	var grid_size := Vector2(_x_grid_size, y_grid_size)
	
	$Grid.material.set_shader_param("grid_size", grid_size)
	$Grid.material.set_shader_param("dashboard_size", rect_size)
	for widget in $Widgets.get_children():
		var widget_resizer = widget.get_node("WidgetResizer")
		widget_resizer.grid_size.x = _x_grid_size
		
	yield(VisualServer, "frame_post_draw")
	for widget in $Widgets.get_children():
		var widget_resizer = widget.get_node("WidgetResizer")
		widget_resizer.parent_reference.set_deferred("rect_global_position" , widget_resizer.rect_global_position)
		widget_resizer.parent_reference.set_deferred("rect_size", widget_resizer.rect_size)
		

