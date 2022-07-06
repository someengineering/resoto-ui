tool
extends Line2D
var poly : PoolVector2Array


func _ready():
	set_as_toplevel(true)
	get_parent().connect("visibility_changed", self, "change_visible")
	
func change_visible():
	visible = get_parent().is_visible_in_tree()


func _on_Serie_draw():
	if points.size() > 0:
		poly = [Vector2.ZERO]
		poly.append_array(points)
		poly.append(Vector2(points[points.size()-1].x, 0))
		
		$Polygon2D.polygon = poly
		$Polygon2D.color = default_color
		$Polygon2D.color.a = 0.05
		
		var vertex_colors : PoolColorArray = []
		vertex_colors.resize(poly.size())
		vertex_colors.fill($Polygon2D.color)
		vertex_colors[0] = Color(0,0,0,-0.1)
		vertex_colors[vertex_colors.size()-1] = Color(0,0,0,-0.1)
		$Polygon2D.vertex_colors = vertex_colors
	else:
		$Polygon2D.polygon = []
