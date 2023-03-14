extends Node2D
class_name GraphLayoutNeighborhood

const NodeColumnWidth : float = 400.0
const GraphLayoutNodeScene = preload("res://components/graph/Elements/GraphNode.tscn")
const GraphLayoutEdgeScene = preload("res://components/graph/Elements/GraphEdge.tscn")

var graph_parent:Node			= null
var graph_navigator:Node		= null
var parent:Node					= null

var main_node_id:String			= ""

var edges:Array
var nodes:Dictionary

var node_scenes:Dictionary
var edge_scenes:Array

var edges_to:Dictionary
var edges_from:Dictionary

var sorted_layout:Dictionary = {
	"in_2" : {},
	"in_1" : [],
	"main" : [],
	"out_1" : [],
	"out_2" : {},
}

var horizonal_layers : Dictionary

onready var main_node_container = $Nodes/Content/MainNodeContainer
onready var inbound = $Nodes/Content/Inbound
onready var outbound = $Nodes/Content/Outbound


func create_graph(_nodes, _edges):
	edges = _edges
	nodes = _nodes
	modulate.a = 0.0
	create_layout()
	sort_layout()
	yield(VisualServer, "frame_post_draw")
	calc_layers()
	yield(VisualServer, "frame_post_draw")
	create_edges()
	center_graph()
	modulate.a = 1.0


func sort_layout():
	# create quick access dicts
	for e in edges:
		if not edges_to.has(e.to):
			edges_to[e.to] = []
		edges_to[e.to].append(e.from)
		if not edges_from.has(e.from):
			edges_from[e.from] = []
		edges_from[e.from].append(e.to)
	
	for current_node in sorted_layout.in_1:
		var biggest_pos := -1
		for other_node in sorted_layout.in_1:
			if current_node == other_node:
				continue
			if edges_to.has(other_node) and edges_to[other_node].has(current_node):
				var parent = node_scenes[other_node].control_node.get_parent()
				parent.move_child(node_scenes[other_node].control_node, 0)
				var pos_index = node_scenes[other_node].control_node.get_index()
				if pos_index > biggest_pos:
					biggest_pos = pos_index
					parent.move_child(node_scenes[current_node].control_node, pos_index)
	
	for current_node in sorted_layout.out_1:
		var biggest_pos := -1
		for other_node in sorted_layout.out_1:
			if current_node == other_node:
				continue
			if edges_to.has(other_node) and edges_to[other_node].has(current_node):
				var parent = node_scenes[other_node].control_node.get_parent()
				parent.move_child(node_scenes[other_node].control_node, 0)
				var pos_index = node_scenes[other_node].control_node.get_index()
				if pos_index > biggest_pos:
					biggest_pos = pos_index
					parent.move_child(node_scenes[current_node].control_node, pos_index)


func calc_layers():
	for node_scene in node_scenes.values():
		node_scene["layer"] = round(node_scene.scene.rect_global_position.x/100)
	
	for i in 3:
		for e in edges:
			if node_scenes[e.from].layer != node_scenes[e.to].layer:
				continue
			var from_x : float = node_scenes[e.from].scene.rect_global_position.x - (node_scenes[e.from].scene.rect_min_size.x-NodeColumnWidth)
			var to_x : float = node_scenes[e.to].scene.rect_global_position.x - (node_scenes[e.to].scene.rect_min_size.x-NodeColumnWidth)
			if round(from_x/100) == round(to_x/100):
				node_scenes[e.from].scene.rect_min_size.x += NodeColumnWidth


func create_layout():
	sorted_layout.main = main_node_id
	
	var remaining_edges := []
	for e in edges:
		if e.from == main_node_id:
			sorted_layout.out_1.append(e.to)
		elif e.to == main_node_id:
			sorted_layout.in_1.append(e.from)
		else:
			remaining_edges.append(e)
	
	for e in remaining_edges:
		for e_out_one in sorted_layout.out_1:
			if e.from == e_out_one:
				sorted_layout.out_2[e.to] = e.from
		for e_in_one in sorted_layout.in_1:
			if e.to == e_in_one:
				sorted_layout.in_2[e.from] = e.to
	
	while node_scenes.size() < nodes.keys().size():
		for node_id in nodes.keys():
			if node_scenes.has(nodes[node_id].id):
				continue
			var temp_node = GraphLayoutNodeScene.instance()
			temp_node.id = node_id
			temp_node.node_id = nodes[node_id].id
			temp_node.parent_id = ""
			temp_node.metadata = nodes[node_id]
			temp_node.connect("node_clicked", graph_parent, "on_node_clicked")
			graph_navigator.connect("change_zoom", temp_node, "on_change_zoom")
			
			var node_wrapper = Control.new()
			node_wrapper.rect_min_size = Vector2(NodeColumnWidth, 100)
			node_wrapper.add_child(temp_node)
			node_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			if sorted_layout.main == temp_node.node_id:
				temp_node.node_display_mode = temp_node.Mode.ROOT
				main_node_container.add_child(node_wrapper)
				add_node_scene(temp_node.node_id, node_wrapper, node_wrapper, node_wrapper)
			
			# Outbound Level 1
			elif sorted_layout.out_1.has(temp_node.node_id):
				temp_node.node_display_mode = temp_node.Mode.OUTBOUND
				var outbound_wrapper = HBoxContainer.new()
				var outbound_wrapper_children = VBoxContainer.new()
				outbound_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_END
				outbound_wrapper.alignment = BoxContainer.ALIGN_END
				outbound_wrapper_children.alignment = BoxContainer.ALIGN_CENTER
				outbound_wrapper.add_child(node_wrapper)
				outbound_wrapper.add_child(outbound_wrapper_children)
				outbound.add_child(outbound_wrapper)
				add_node_scene(temp_node.node_id, node_wrapper, outbound_wrapper_children, outbound_wrapper)
				
			# Inbound Level 1
			elif sorted_layout.in_1.has(temp_node.node_id):
				temp_node.node_display_mode = temp_node.Mode.INBOUND
				var inbound_wrapper = HBoxContainer.new()
				var inbound_wrapper_children = VBoxContainer.new()
				inbound_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_END
				inbound_wrapper_children.alignment = BoxContainer.ALIGN_CENTER
				inbound_wrapper.add_child(inbound_wrapper_children)
				inbound_wrapper.add_child(node_wrapper)
				inbound.add_child(inbound_wrapper)
				add_node_scene(temp_node.node_id, node_wrapper, inbound_wrapper_children, inbound_wrapper)
			
			# Node is outbound level 2
			elif sorted_layout.out_2.keys().has(temp_node.node_id):
				if not sorted_layout.out_2.has(temp_node.node_id) or not node_scenes.has(sorted_layout.out_2[temp_node.node_id]):
					continue
				node_scenes[sorted_layout.out_2[temp_node.node_id]].attach_to.add_child(node_wrapper)
				add_node_scene(temp_node.node_id, node_wrapper, node_wrapper, node_wrapper)
			
			# Node is inbound level 2
			elif sorted_layout.in_2.keys().has(temp_node.node_id):
				if not sorted_layout.in_2.has(temp_node.node_id) or not node_scenes.has(sorted_layout.in_2[temp_node.node_id]):
					continue
				node_scenes[sorted_layout.in_2[temp_node.node_id]].attach_to.add_child(node_wrapper)
				add_node_scene(temp_node.node_id, node_wrapper, node_wrapper, node_wrapper)


func center_graph():
	var window_center : Vector2 = OS.get_real_window_size()/2
	position -= (node_scenes[main_node_id].scene.rect_global_position - window_center) / graph_navigator.zoom_level


func create_edges():
	for e in edges:
		var tempEdge = GraphLayoutEdgeScene.instance()
		tempEdge.id = e.from+"##to##"+e.to
		tempEdge.source_id = e.from
		if tempEdge.source_id == main_node_id:
			tempEdge.edge_display_mode = tempEdge.Mode.OUTBOUND
		tempEdge.target_id = e.to
		edge_scenes.append(tempEdge)
		$Edges.add_child(tempEdge)
	
	for layout_edge in edge_scenes:
		var from = node_scenes[layout_edge.source_id].scene.rect_global_position / graph_navigator.zoom_level
		var to = node_scenes[layout_edge.target_id].scene.rect_global_position / graph_navigator.zoom_level
		layout_edge.update_line(from, to)


func add_node_scene(_node_id:String, _scene:Node, _attach_to:Node, _control_node:Node):
	node_scenes[_node_id] = { "scene": _scene, "attach_to": _attach_to, "control_node": _control_node }


func remove_all():
	queue_free()
