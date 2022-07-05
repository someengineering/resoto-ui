extends Line2D

var from:Node
var to:Node


func update_line():
	set_point_position(0, (from.rect_global_position + from.rect_size/2))
	set_point_position(1, (to.rect_global_position + to.rect_size/2))
