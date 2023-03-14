extends Control

const GraphViz = preload("res://components/graph/Elements/SimpleNeighborhood.tscn")

var edges:Array = []
var nodes:Dictionary = {}
var graph_visualisation:GraphLayoutNeighborhood
#var graph_visualisation:GraphLayoutAlgorithmCose
var last_query:= ""
var main_node_id:= ""

onready var graph_navigator = $GraphNavigator

func _ready() -> void:
	on_node_clicked("root")


func new_graph_request(_search:String):
	if graph_visualisation != null:
		graph_visualisation.queue_free()
	graph_navigator.reset_position()
	edges.clear()
	nodes.clear()
	API.cli_execute_json(_search, self)


func on_node_clicked(_node_id:String):
	main_node_id = _node_id
	var search_syntax = "search --with-edges id(\"%s\") <-[0:2]->" % main_node_id
	new_graph_request(search_syntax)
	

func _on_cli_execute_json_data(data) -> void:
	var new_resource = data
	if data.type == "edge":
		edges.append(data)
	else:
		nodes[data.id] = data
		

func _on_cli_execute_json_done(error:int, response:UserAgent.Response) -> void:
	if error:
		print(error)
	else:
		var result = response.transformed["result"]
		graph_visualisation = GraphViz.instance()
		$GraphNavigator/Content.add_child(graph_visualisation)
		graph_visualisation.main_node_id = main_node_id
		graph_visualisation.graph_navigator = graph_navigator
		graph_visualisation.graph_parent = self
		graph_visualisation.create_graph(nodes, edges)
		#graph_visualisation.create_graph_nodes($GraphNavigator/Content, nodes, edges)
		#_on_StepButton_pressed()


func _on_StepButton_pressed():
	on_node_clicked(main_node_id)


func _on_Back_pressed():
	var _parent_id = ""
	var search_syntax = "search --with-edges id(\"" + _parent_id + "\") -[0:2]->"
	new_graph_request(search_syntax)
