extends Line2D
class_name GraphLayoutEdge

var source_id
var target_id
var id


func update_line(from:Vector2, to:Vector2):
	clear_points()
	var dir_to : Vector2 = from.direction_to(to)
	var curve_intensity : float = ease(abs(dir_to.y), 0.8)
	var rotation_dir := 1.0 if from.y < to.y else -1.0
	
	var to_mid : Vector2 = (dir_to*from.distance_to(to)*0.35).rotated(0.4*rotation_dir*curve_intensity)
	var from_mid : Vector2 = (-dir_to*from.distance_to(to)*0.35).rotated(-0.4*rotation_dir*curve_intensity)
	var curve : Curve2D = Curve2D.new()
	curve.add_point(from, Vector2.ZERO, to_mid)
	curve.add_point(to, from_mid)
	for bp in curve.tessellate(5, 1):
		add_point(bp)
