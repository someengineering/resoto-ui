tool
extends Line2D
var poly : PoolVector2Array

var maximum_y = -INF
var minimum_y = INF

var zero_position := 0.0

onready var indicator := $Indicator
onready var polygon := $Polygon2D


func show_indicator(point : Vector2) -> void:
	indicator.position = point


func _on_Serie_draw() -> void:
	indicator.color = default_color
	self_modulate = default_color
	var zero : float = min(zero_position, 0.0)
	if points.size() > 0:
		update_min_max()
		poly = [Vector2(points[0].x, zero)]
		poly.append_array(points)
		poly.append(Vector2(points[points.size()-1].x, zero)) 
		
		polygon.polygon = poly
		polygon.color = default_color
		polygon.color.a = 0.1

	else:
		polygon.polygon = []


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
