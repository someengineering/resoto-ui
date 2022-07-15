tool
extends Line2D
var poly : PoolVector2Array

var maximum_y = -INF
var minimum_y = INF

onready var indicator := $Indicator

func _ready():
	set_as_toplevel(true)
	get_parent().connect("visibility_changed", self, "change_visible")
	indicator.visible = false
	
func change_visible():
	visible = get_parent().is_visible_in_tree()

func show_indicator(point : Vector2):
	indicator.position = point

func _on_Serie_draw():
	indicator.color = default_color
	self_modulate = default_color
	if points.size() > 0:
		update_min_max()
		
		poly = [Vector2(points[0].x, 0)]
		poly.append_array(points)
		poly.append(Vector2(points[points.size()-1].x, 0))
		
		$Polygon2D.polygon = poly
		$Polygon2D.color = default_color
		$Polygon2D.color.a = 0.05

		var vertex_colors : PoolColorArray = []
		vertex_colors.resize(poly.size())
		vertex_colors.fill(default_color)
	
		
		for i in points.size():
			vertex_colors[i+1].a = 0.2 * points[i].y /(- maximum_y)
		
		vertex_colors[0] = Color(0,0,0,0)
		vertex_colors[vertex_colors.size()-1] = Color(0,0,0,0)
		$Polygon2D.vertex_colors = vertex_colors
	else:
		$Polygon2D.polygon = []
		
func update_min_max():
	var maxy = -INF
	var miny = INF
	for point in points:
		if -point.y > maxy:
			maxy = -point.y
		if -point.y < miny:
			miny = -point.y
			
	maximum_y = maxy
	minimum_y = miny
