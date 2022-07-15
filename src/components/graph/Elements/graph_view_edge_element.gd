extends Line2D
class_name GraphLayoutEdge

var source_id
var target_id
var ideal_length
var elasticity
var id

func update_line(from, to):
	points[0] = from
	points[1] = to
