tool
extends Line2D
var poly : PoolVector2Array

var maximum_y = -INF
var minimum_y = INF

onready var indicator := $Indicator


func show_indicator(point : Vector2) -> void:
	indicator.position = point

func _on_Serie_draw() -> void:
	indicator.color = default_color
	self_modulate = default_color
	if points.size() > 0:
		update_min_max()
		
		poly = [Vector2(points[0].x, 0)]
		poly.append_array(points)
		poly.append(Vector2(points[points.size()-1].x, 0)) 
		
		$Polygon2D.polygon = poly
		$Polygon2D.color = default_color
		$Polygon2D.color.a = 0.1

	else:
		$Polygon2D.polygon = []
		
func update_min_max() -> void:
	var maxy = -INF
	var miny = INF
	for point in points:
		if -point.y > maxy:
			maxy = -point.y
		if -point.y < miny:
			miny = -point.y
			
	maximum_y = maxy
	minimum_y = miny
