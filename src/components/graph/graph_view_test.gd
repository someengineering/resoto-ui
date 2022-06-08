extends Control

onready var graph = $GraphEdit

var nodes:Dictionary = {}

func _ready() -> void:
	API.cli_execute_json("search --with-edges id=root -[0:2]->", self)


func _on_cli_execute_json_data(data) -> void:
	var new_resource = data
	if data.type == "edge":
		add_graph_edge(data)
	else:
		add_graph_element(data)


func add_graph_element(_data:Dictionary) -> void:
	var graph_node: GraphNode = GraphNode.new()
	nodes[_data.id] = graph_node
	graph.add_child(graph_node)
	graph_node.rect_min_size = Vector2(200, 100)
	graph_node.title = _data.reported.name
	
	var new_slot:Label = add_label("")
	new_slot.align = Label.ALIGN_CENTER
	graph_node.add_child(new_slot)
	
	for key in _data.metadata.keys():
		if key != "descendant_summary":
			var new_text:String = key + ": " + str(_data.metadata[key]).left(15)
			graph_node.add_child(add_label(new_text))


func add_graph_edge(_data:Dictionary) -> void:
	var from_node: GraphNode = nodes[_data.from]
	from_node.set_slot_enabled_right(0, true)
	var to_node: GraphNode = nodes[_data.to]
	to_node.set_slot_enabled_left(0, true)
	to_node.set_slot_color_left(0, Color.lightcoral)
	from_node.set_slot_color_right(0, Color.darkturquoise)
	graph.connect_node(from_node.name, 0, to_node.name, 0)
	pass


func add_label(_text:String) ->Label:
	var label = Label.new()
	label.text = _text
	return label


func _on_cli_execute_json_done(error:int, response:UserAgent.Response) -> void:
	if error:
		print(error)
	else:
		var result = response.transformed["result"]
