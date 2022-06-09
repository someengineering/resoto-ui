extends Control

onready var widgets : Control = $Widgets
onready var grid_background : ColorRect = $Grid

export var x_grid_ratio := 10.0
export var y_grid_size := 100.0
export var grid_margin := Vector2(5,5)

onready var _x_grid_size := rect_size.x / x_grid_ratio

func _ready():
	grid_background.rect_size = rect_size
	
	var grid_size := Vector2(_x_grid_size, y_grid_size)
	for widget in $Widgets.get_children():
		var widget_resizer = widget.get_node("WidgetResizer")
		widget.rect_position = widget.rect_position.snapped(grid_size) + grid_margin
		widget.rect_size = widget.rect_size.snapped(grid_size) - 2*grid_margin

		widget_resizer.parent_reference.rect_global_position = widget_resizer.rect_global_position
		widget_resizer.parent_reference.rect_size = widget_resizer.rect_size

		widget_resizer.set_anchors()
		
func _on_Grid_resized() -> void:
	_x_grid_size = rect_size.x / x_grid_ratio

	$Grid.material.set_shader_param("grid_x_ratio", x_grid_ratio)
	for widget in $Widgets.get_children():
		var widget_resizer = widget.get_node("WidgetResizer")
		widget_resizer.dashboard = self
		widget_resizer.grid_size.x = _x_grid_size
		
	yield(get_tree(),"idle_frame")
	for widget in $Widgets.get_children():
		var widget_resizer = widget.get_node("WidgetResizer")
		widget_resizer.parent_reference.set_deferred("rect_global_position" , widget_resizer.rect_global_position)
		widget_resizer.parent_reference.set_deferred("rect_size", widget_resizer.rect_size)
		

