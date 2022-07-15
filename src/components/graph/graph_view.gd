extends Control

var edges:Array = []
var nodes:Dictionary = {}
var graph_visualisation:GraphLayoutAlgorithmCose
var last_query:= ""

onready var graph_navigator = $GraphNavigator

func _ready() -> void:
	new_graph_request("search --with-edges id=root -[0:1]->")


func new_graph_request(_search:String):
	if graph_visualisation != null:
		graph_visualisation.remove_all()
	edges.clear()
	nodes.clear()
	API.cli_execute_json(_search, self)


func on_node_clicked(_node_id:String):
	var search_syntax = "search --with-edges id(\"" + _node_id + "\") -[0:1]->"
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
		graph_visualisation = GraphLayoutAlgorithmCose.new()
		graph_visualisation.graph_navigator = graph_navigator
		graph_visualisation.graph_parent = self
		graph_visualisation.create_graph_nodes($GraphNavigator/Content, nodes, edges)
		_on_StepButton_pressed()


func _on_StepButton_pressed():
	graph_visualisation.layout_info.temperature = graph_visualisation.options.initialTemp
	for i in 200:
		if not graph_visualisation.layout_loop():
			break
		if i%10 == 0:
			yield(get_tree(), "idle_frame")
	graph_visualisation.end()


func _on_Back_pressed():
	var _parent_id = ""
	var search_syntax = "search --with-edges id(\"" + _parent_id + "\") -[0:1]->"
	new_graph_request(search_syntax)
