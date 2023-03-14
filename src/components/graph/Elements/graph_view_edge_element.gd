extends Line2D
class_name GraphLayoutEdge

const MaterialInbound = preload("res://components/graph/Elements/graph_edge_material_inbound.tres")
const MaterialOutbound = preload("res://components/graph/Elements/graph_edge_material_outbound.tres")

enum Mode {OUTBOUND, INBOUND}

var edge_display_mode:int	= Mode.INBOUND

var source_id
var target_id
var ideal_length
var elasticity
var id


func _ready():
	set_mode(edge_display_mode)


func update_line(from:Vector2, to:Vector2):
	clear_points()
	var dir_to : Vector2 = from.direction_to(to)
	var curve_intensity : float = abs(dir_to.y)
	var rotation_dir := 1.0 if from.y < to.y else -1.0
	
	var to_mid : Vector2 = (dir_to*from.distance_to(to)*0.3).rotated(0.4*rotation_dir*curve_intensity)
	var from_mid : Vector2 = (-dir_to*from.distance_to(to)*0.3).rotated(-0.4*rotation_dir*curve_intensity)
	var curve : Curve2D = Curve2D.new()
	curve.add_point(from, Vector2.ZERO, to_mid)
	curve.add_point(to, from_mid)
	for bp in curve.tessellate(5, 2):
		add_point(bp)
#	var point_divider : float = 1.0 / float(get_point_count()-1)
#	for i in get_point_count():
#		points[i] = lerp(from, to, point_divider*i)


func set_mode(_mode:int):
	edge_display_mode = _mode
	if edge_display_mode == Mode.INBOUND:
		material = MaterialInbound
	#	modulate = Color("#762dd7")
	else:
		material = MaterialOutbound
	#	modulate = Color("#da9eff")
