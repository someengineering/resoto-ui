extends Node
class_name GraphAStar

const MAX_INT_32 : int = 2147483647
var astar := AStar2D.new()
var start_id : int = -1
var end_id : int = -1
var orig_data : Dictionary = {}


func get_shortest_path(result:Array, start_node_id:String, end_node_id:String) -> Array:
	orig_data.clear()
	astar.clear()
	start_id = -1
	end_id = -1
	for r in result:
		if r.type == "edge":
			var from_id : int = _to32(str(r.from).hash())
			var to_id : int = _to32(str(r.to).hash())
			astar.connect_points(from_id, to_id, true)
		
		if r.type == "node":
			var id:int = _to32(str(r.id).hash())
			orig_data[id] = r
			astar.add_point(id, Vector2.ZERO)
			if r.id == start_node_id:
				start_id = id
			elif r.id == end_node_id:
				end_id = id
	
	if orig_data.size() == 1:
		return [orig_data[orig_data.keys()[0]]]
	
	if start_id == -1 or end_id == -1 or orig_data.empty():
		return []
	return path_to_nodes(astar.get_id_path(start_id, end_id))


func path_to_nodes(path:Array) -> Array:
	var node_array : Array = []
	for i in path:
		node_array.append(orig_data[i])
	return node_array


func _to32(_int:int) -> int:
	var s_id = str(_int)
	var len_diff = abs(str(MAX_INT_32).length()-s_id.length())+1
	s_id = s_id.right(len_diff)
	return int(s_id)
