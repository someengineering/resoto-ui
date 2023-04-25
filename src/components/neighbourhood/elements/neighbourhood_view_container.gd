extends Node2D
class_name GraphLayoutNeighborhood

signal graph_generated

const MAX_NODES_PER_PREDECESSOR : int = 5

const NodeColumnWidth : float = 400.0
const GraphLayoutNodeScene = preload("res://components/neighbourhood/elements/neighbourhood_view_node_element.tscn")
const GraphLayoutEdgeScene = preload("res://components/neighbourhood/elements/neighbourhood_view_edge_element.tscn")
const GraphLevelOneWrapper = preload("res://components/neighbourhood/elements/neighbourhood_level_one_wrapper.tscn")
const GraphNodeWrapper = preload("res://components/neighbourhood/elements/neighbourhood_node_wrapper.tscn")

var graph_parent:Node			= null
var graph_navigator:Node		= null

var main_node_id:String			= ""

var edges:Array
var nodes:Dictionary

var node_scenes:Dictionary
var node_scenes_objects:Dictionary
var edge_scenes:Array
var edge_scenes_from:Dictionary
var edge_scenes_to:Dictionary

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
onready var edges_container = $Edges


func create_graph(_nodes, _edges):
	edges = _edges
	nodes = _nodes
	modulate.a = 0.0
	create_layout()
	sort_layout()
	yield(VisualServer, "frame_post_draw")
	calc_layers()
	adjust_width()
	yield(VisualServer, "frame_post_draw")
	adjust_layers()
	yield(VisualServer, "frame_post_draw")
	create_edges()
	modulate.a = 1.0
	emit_signal("graph_generated")


func get_visible_rect() -> Rect2:
	var rect : Rect2 = $Nodes/Content.get_rect()
	rect.size.x -= NodeColumnWidth
	return rect


func sort_layout():
	for e in edges:
		edges_to[e.to] = []
		edges_from[e.from] = []
	
	for e in edges:
		edges_to[e.to].append(e.from)
		edges_from[e.from].append(e.to)
	
	var kind_names := {}
	for node_id in node_scenes:
		var kind_name : String = node_scenes[node_id].node_scene.metadata.reported.kind
		if not kind_names.has(kind_name):
			kind_names[kind_name] = []
		kind_names[kind_name].append([node_id, node_scenes[node_id].node_scene.metadata.reported.name.to_lower()])
	for kind_key in kind_names:
		kind_names[kind_key].sort_custom(self, "sort_by_names")
	var kind_name_keys : Array = kind_names.keys()
	kind_name_keys.sort()
	kind_name_keys.invert()
	

	for kind_name_key in kind_name_keys:
		for node_id in kind_names[kind_name_key]:
			var control : Control = node_scenes[node_id[0]].control_node
			control.get_parent().move_child(control, 0)
	
	# I left this here against good practice, but it took a while to make
	# And eventually we want this back in at some point.
#	var edge_from_counts := []
#	for edge in edges_from:
#		var count : int = edges_from[edge].size()
#		if count > 1 and sorted_layout.in_1.has(edge):
#			edge_from_counts.append([edge, edges_from[edge].size()])
#	edge_from_counts.sort_custom(self, "sort_by_outgoing")
#
#	for edge_info in edge_from_counts:
#		var control : Control = node_scenes[edge_info[0]].control_node
#		var c_c = control.get_parent().get_child_count()
#		control.get_parent().move_child(control, round(c_c/2))
#
#	var edge_to_counts := []
#	for edge in edges_from:
#		var count : int = edges_from[edge].size()
#		if count > 1 and sorted_layout.out_1.has(edge):
#			edge_to_counts.append([edge, edges_from[edge].size()])
#
#	edge_to_counts.sort_custom(self, "sort_by_outgoing")
#	for edge_info in edge_to_counts:
#		var control : Control = node_scenes[edge_info[0]].control_node
#		var c_c = control.get_parent().get_child_count()
#		control.get_parent().move_child(control, round(c_c/2))


static func sort_by_names(a, b):
	return a[1] > b[1]


func adjust_width():
	var main_size : float = max(outbound.rect_size.y, inbound.rect_size.y) * 0.15
	node_scenes[main_node_id].control_node.rect_min_size.x += main_size
	node_scenes[main_node_id].node_scene.position.x += main_size/2

	for out in sorted_layout.out_1:
		node_scenes[out].scene.rect_min_size.x += node_scenes[out].attach_to.rect_size.y * 0.15 + main_size*0.5


func calc_layers():
	for node_scene in node_scenes.values():
		if node_scene.scene != null:
			node_scene["layer"] = round(node_scene.scene.rect_global_position.x/1000)


func adjust_layers():
	var no_changes := false
	var iterations := 0
	while not no_changes:
		var layer_changes := []
		var max_move := 3000.0
		for e in edges:
			if node_scenes[e.from].scene == null or node_scenes[e.to].scene == null:# or node_scenes[e.from].layer != node_scenes[e.to].layer:
				continue
			if node_scenes[e.from].layer == node_scenes[e.to].layer:
				if node_scenes[e.to].side == 1:
					layer_changes.append([node_scenes[e.to], 1])
					var w : float = min(node_scenes[e.to].control_node.get_parent().rect_size.y*1.5, max_move)
					node_scenes[e.to].control_node.rect_min_size.x = 1000.0 + w * (iterations+1)
				
				elif node_scenes[e.to].side == -1:
					layer_changes.append([node_scenes[e.from], -1])
					var w : float = min(node_scenes[e.from].control_node.get_parent().rect_size.y*1.5, max_move)
					node_scenes[e.from].scene.rect_min_size.x = 1000.0 + w * (iterations+1)
		
		var changed_layers := []
		for l in layer_changes:
			if changed_layers.has(l):
				continue
			changed_layers.append(l)
			l[0].layer += l[1]
		
		no_changes = layer_changes.empty()
		iterations += 1


func create_layout():
	sorted_layout.main = main_node_id
	
	var remaining_edges := []
	for e in edges:
		if e.from == main_node_id:
			sorted_layout.out_1.append(e.to)
			sorted_layout.out_2[e.to] = []
		elif e.to == main_node_id:
			sorted_layout.in_1.append(e.from)
			sorted_layout.in_2[e.from] = []
		else:
			remaining_edges.append(e)
	
	for e in remaining_edges:
		for e_out_two in sorted_layout.out_2:
			if e_out_two == e.from:
				sorted_layout.out_2[e_out_two].append(e.to)
		for e_in_two in sorted_layout.in_2:
			if e_in_two == e.to:
				sorted_layout.in_2[e_in_two].append(e.from)
	
	remaining_edges.clear()
	
	# create center (lvl 0) element:
	var main_node = create_node(main_node_id, graph_parent, graph_navigator)
	var main_wrapper = create_wrapper(main_node)
	main_node.node_display_mode = main_node.Mode.ROOT
	main_node_container.add_child(main_wrapper)
	add_node_scene(main_node, main_node.node_id, main_wrapper, main_wrapper, main_wrapper, 0)
	node_scenes_objects[main_node_id] = main_node
	
	# create lvlv 1 elements:
	for _node_id in sorted_layout.out_1:
		var _node = create_node(_node_id, graph_parent, graph_navigator)
		var _wrapper = create_wrapper(_node)
		_node.node_display_mode = _node.Mode.OUTBOUND
		var new_lev_wrapper = GraphLevelOneWrapper.instance()
		new_lev_wrapper.add_wrapper(_wrapper, true)
		outbound.add_child(new_lev_wrapper)
		add_node_scene(_node, _node_id, _wrapper, new_lev_wrapper.get_children_container(), new_lev_wrapper, 1)
		node_scenes_objects[_node_id] = _node
		
	for _node_id in sorted_layout.in_1:
		var _node = create_node(_node_id, graph_parent, graph_navigator)
		var _wrapper = create_wrapper(_node)
		_node.node_display_mode = _node.Mode.INBOUND
		var new_lev_wrapper = GraphLevelOneWrapper.instance()
		new_lev_wrapper.add_wrapper(_wrapper, false)
		inbound.add_child(new_lev_wrapper)
		add_node_scene(_node, _node_id, _wrapper, new_lev_wrapper.get_children_container(), new_lev_wrapper, -1)
		node_scenes_objects[_node_id] = _node
	
	for out_2 in sorted_layout.out_2:
		var attach_to : Control = node_scenes[out_2].attach_to
		for _node_id in sorted_layout.out_2[out_2]:
			if node_scenes_objects.has(_node_id):
				continue
			var _node = create_node(_node_id, graph_parent, graph_navigator)
			var _wrapper = create_wrapper(_node)
			_node.node_display_mode = _node.Mode.OUTBOUND
			attach_to.add_child(_wrapper)
			add_node_scene(_node, _node_id, _wrapper, _wrapper, _wrapper, 1)
			node_scenes_objects[_node_id] = _node
	
	for in_2 in sorted_layout.in_2:
		var attach_to : Control = node_scenes[in_2].attach_to
		for _node_id in sorted_layout.in_2[in_2]:
			if node_scenes_objects.has(_node_id):
				continue
			var _node = create_node(_node_id, graph_parent, graph_navigator)
			var _wrapper = create_wrapper(_node)
			_node.node_display_mode = _node.Mode.INBOUND
			attach_to.add_child(_wrapper)
			add_node_scene(_node, _node_id, _wrapper, _wrapper, _wrapper, -1)
			node_scenes_objects[_node_id] = _node


func create_wrapper(_node:GraphLayoutNode):
	var node_wrapper = GraphNodeWrapper.instance()
	node_wrapper.add_child(_node)
	return node_wrapper


func create_node(_node_id:String, _graph_parent:Node, _graph_navigator:Node) -> GraphLayoutNode:
	var temp_node : GraphLayoutNode = GraphLayoutNodeScene.instance()
	temp_node.id = _node_id
	temp_node.node_id = nodes[_node_id].id
	temp_node.parent_id = ""
	temp_node.metadata = nodes[_node_id]
	temp_node.connect("node_clicked", _graph_parent, "on_node_clicked")
	_graph_navigator.connect("change_zoom", temp_node, "on_change_zoom")
	return temp_node


func center_graph():
	var window_center : Vector2 = OS.get_real_window_size()/2
	if not node_scenes.has(main_node_id):
		return
	position -= (node_scenes[main_node_id].scene.rect_global_position - window_center) / graph_navigator.zoom_level


func create_edges():
	for e in edges:
		var tempEdge = GraphLayoutEdgeScene.instance()
		# TEMPORARY: This needs a better solution
#		if not node_scenes[e.from].scene.visible or not node_scenes[e.to].scene.visible:
#			continue
		tempEdge.modulate = node_scenes_objects[e.from].main_color
		tempEdge.id = e.from+"##to##"+e.to
		tempEdge.source_id = e.from
		tempEdge.target_id = e.to
		edge_scenes.append(tempEdge)
		edges_container.add_child(tempEdge)
		if not edge_scenes_from.has(e.from):
			edge_scenes_from[e.from] = []
		if not edge_scenes_to.has(e.to):
			edge_scenes_to[e.to] = []
		edge_scenes_from[e.from].append(tempEdge)
		edge_scenes_to[e.to].append(tempEdge)
	
	for layout_edge in edge_scenes:
		var from = node_scenes[layout_edge.source_id].node_scene.global_position / graph_navigator.zoom_level - graph_parent.rect_global_position
		var to = node_scenes[layout_edge.target_id].node_scene.global_position / graph_navigator.zoom_level - graph_parent.rect_global_position
		layout_edge.update_line(from, to)


func add_node_scene(_node_scene:GraphLayoutNode, _node_id:String, _scene:Node, _attach_to:Node, _control_node:Node, _side:=0):
	_node_scene.connect("node_hovering", self, "_on_node_hovering")
	_node_scene.connect("node_unhovering", self, "_on_node_unhovering")
	node_scenes[_node_id] = {"node_scene": _node_scene, "scene": _scene, "attach_to": _attach_to, "control_node": _control_node, "side" : _side }


func remove_all():
	queue_free()


func _on_node_hovering(node_id:String, metadata:Dictionary):
	_g.emit_signal("tooltip_node", metadata)
	if edge_scenes_from.has(node_id):
		for edge in edge_scenes_from[node_id]:
			edge.self_modulate = Color.white*1.4
	if edges_from.has(node_id):
		for node_scene in edges_from[node_id]:
			node_scenes[node_scene].node_scene.modulate = Color.white*1.4


func _on_node_unhovering(node_id:String):
	_g.emit_signal("tooltip_hide")
	if edge_scenes_from.has(node_id):
		for edge in edge_scenes_from[node_id]:
			edge.self_modulate = Color.white
	if edges_from.has(node_id):
		for node_scene in edges_from[node_id]:
			node_scenes[node_scene].node_scene.modulate = Color.white
