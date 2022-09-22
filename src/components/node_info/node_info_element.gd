extends PanelContainer

var active_request: ResotoAPI.Request

func show_node(node_id:String):
	var search_command = "id(" + node_id + ") <-->"
	active_request = API.graph_search(search_command, self, "graph")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		print("")
		print(active_request.body)
		print("=")
		print(_response.transformed.result)
