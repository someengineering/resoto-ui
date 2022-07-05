extends Control

onready var NodeElem = $NodeElem
onready var EdgeElem = $EdgeElem
onready var graph = $Graph
onready var graph_nodes = $Graph/Nodes
onready var graph_edges = $Graph/Edges

var edges:Array = []
var edges_from:Dictionary = {}
var edges_to:Dictionary = {}
var nodes:Dictionary = {}


const ATTRACTION_CONSTANT := 0.01
const REPULSION_CONSTANT := 100.0
const MAX_DISTANCE := 150.0
const GRAPH_MOVE_SPEED := 1.0
const MAX_DISPLACE := 1000.0
const DEFAULT_DAMPING := 0.99
const DEFAULT_SPRING_LENGTH := 80.0
const DEFAULT_MAX_ITERATIONS := 200


func calc_repulsion_force_pos(node_a_pos, node_b_pos):
	var force = -REPULSION_CONSTANT / node_a_pos.distance_to(node_b_pos)
	return node_a_pos.direction_to(node_b_pos) * force


func calc_attraction_force_pos(node_a_pos, node_b_pos, spring_length):
	var force = ATTRACTION_CONSTANT * max((node_a_pos.distance_to(node_b_pos)) - spring_length, 0)
	return node_a_pos.direction_to(node_b_pos) * force

# Arrange the graph using Spring Electric Algorithm
# returning the nodes positions
func arrange(damping, spring_length, max_iterations, deterministic := false, refine := false):
	var benchmark_start = OS.get_ticks_usec()
	if !deterministic:
		randomize()

	var stop_count = 0
	var iterations = 0
	var total_displacement_threshold: float = 5.0

	while true:
		var total_displacement := 0.0

		for node in nodes.values():
			var current_node_position = node.rect_position
			var net_force = Vector2.ZERO

			for other_node in nodes.values():
				if node == other_node:
					continue

				var other_node_pos = other_node.rect_position

				if !has_edge_to(node, other_node):
					if current_node_position.distance_to(other_node_pos) < MAX_DISTANCE:
						net_force += (
							calc_repulsion_force_pos(current_node_position, other_node_pos)
						)
				else:
					var attr = calc_attraction_force_pos(
						current_node_position,
						other_node_pos,
						spring_length
					)
					net_force += attr

			node.velocity = ((node.velocity + net_force) * damping * GRAPH_MOVE_SPEED).clamped(
				MAX_DISPLACE
			)
			damping *= 0.9999999
			node.rect_position += node.velocity
			total_displacement += node.velocity.length()

		iterations += 1
		if total_displacement < total_displacement_threshold:
			stop_count += 1
		if stop_count > 10:
			break
		if iterations > max_iterations:
			break

		if false:
			center_diagram()
			update_connection_lines()
		yield(get_tree(), "idle_frame")

	center_diagram()
	update_connection_lines()


	var benchmark_end = OS.get_ticks_usec()
	var benchmark_time = (benchmark_end - benchmark_start) / 1000000.0
	prints("Time to calculate {0} iterations: {1}".format([iterations - 1, benchmark_time]))

#	emit_signal("order_done", saved_node_positions)


func center_diagram():
	return


func update_connection_lines():
	for edge in edges:
		edge.update_line()


func _ready() -> void:
	API.cli_execute_json("search --with-edges id=root -[0:2]->", self)


func _on_cli_execute_json_data(data) -> void:
	var new_resource = data
	if data.type == "edge":
		add_graph_edge(data)
	else:
		add_graph_element(data)


func add_graph_element(_data:Dictionary) -> void:
	var graph_node: Label = NodeElem.duplicate()
	graph_node.show()
	nodes[_data.id] = graph_node
	graph_nodes.add_child(graph_node)
	graph_node.text = _data.reported.name.left(20)
	graph_node.rect_position = Vector2(rand_range(50, 600), rand_range(50, 600))
	
	return
	for key in _data.metadata.keys():
		if key != "descendant_summary":
			var new_text:String = key + ": " + str(_data.metadata[key]).left(15)
			graph_node.add_child(add_label(new_text))


func add_graph_edge(_data:Dictionary) -> void:
	var new_edge:Line2D = EdgeElem.duplicate()
	var from_node: Label = nodes[_data.from]
	var to_node: Label = nodes[_data.to]
	
	edges.append(new_edge)
	nodes[_data.from].connections.append(nodes[_data.to])
	nodes[_data.to].connections.append(nodes[_data.from])
	
	new_edge.to = to_node
	new_edge.from = from_node
	graph_edges.add_child(new_edge)
	new_edge.update_line()
	new_edge.show()


func has_edge_to(node, other_node):
	return node.connections.has(other_node)


func add_label(_text:String) ->Label:
	var label = Label.new()
	label.text = _text
	return label


func _on_cli_execute_json_done(error:int, response:UserAgent.Response) -> void:
	if error:
		print(error)
	else:
		var result = response.transformed["result"]
		arrange(DEFAULT_DAMPING, DEFAULT_SPRING_LENGTH, DEFAULT_MAX_ITERATIONS, true)
