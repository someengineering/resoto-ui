extends Control

signal clicked_node(node_id)

const GraphViz = preload("res://components/neighbourhood/elements/neighbourhood_view_container.tscn")

export(bool) var use_for_navigation := false

var active_request : ResotoAPI.Request
var edges:Array = []
var nodes:Dictionary = {}
var graph_visualisation:GraphLayoutNeighborhood
var last_query:= ""
var main_node_id:= ""

onready var graph_navigator = $GraphNavigator


func new_graph_request(_search:String):
	if graph_visualisation != null:
		graph_visualisation.queue_free()
	graph_navigator.reset_position()
	edges.clear()
	nodes.clear()
	active_request = API.graph_search(_search, self)


func on_node_clicked(_node_id:String):
	if graph_navigator.drag_changed:
		return
		
	if use_for_navigation:
		emit_signal("clicked_node", _node_id)
		return
	else:
		display_node(_node_id)

func display_node(_node_id:String):
	main_node_id = _node_id
	var search_syntax = "id(\"%s\") <-[0:2]->" % main_node_id
	new_graph_request(search_syntax)


func _on_graph_search_done(error:int, response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Neighbourhood View", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	
	if response.transformed.has("result"):
		create_view_from_response(response.transformed["result"])


func create_view_from_response(result:Array):
	create_edges_and_nodes(result)
	graph_visualisation = GraphViz.instance()
	$GraphNavigator/Content.add_child(graph_visualisation)
	graph_visualisation.main_node_id = main_node_id
	graph_visualisation.graph_navigator = graph_navigator
	graph_visualisation.graph_parent = self
	graph_visualisation.create_graph(nodes, edges)
	graph_visualisation.connect("graph_generated", self, "center_graph")


var graph_padding := Vector2(400, 150)
func center_graph():
	var vis_rect : Rect2 = graph_visualisation.get_visible_rect()
	var window_size : Vector2 = get_global_rect().size
	var scaling : Vector2 = (window_size-graph_padding) / vis_rect.size
	var zoom_factor : float = scaling.x if scaling.x < scaling.y else scaling.y
	zoom_factor = clamp(zoom_factor, graph_navigator.MIN_ZOOM, graph_navigator.MAX_ZOOM)
	graph_navigator.set_zoom(zoom_factor)
	graph_navigator.content.position = (graph_padding/2) - Vector2(100.0*zoom_factor, -15)
	graph_navigator.content.position += ((window_size - vis_rect.size*zoom_factor)-graph_padding)/2


func create_edges_and_nodes(_result:Array):
	for data in _result:
		if data.type == "node":
			nodes[data.id] = data
		else:
			edges.append(data)


func _on_StepButton_pressed():
	on_node_clicked(main_node_id)


func _on_Back_pressed():
	var _parent_id = ""
	var search_syntax = "id(\"%s\") <-[0:2]->" % _parent_id
	new_graph_request(search_syntax)


func _on_ButtonZoomCenter_pressed():
	center_graph()
