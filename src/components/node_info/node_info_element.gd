extends PanelContainer

var active_request:ResotoAPI.Request
var current_node_id:String
var current_result:Array

func show_node(node_id:String):
	current_node_id = node_id
	var search_command = "id(" + node_id + ") <-[0:]->"
	active_request = API.graph_search(search_command, self, "graph")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		current_result = _response.transformed.result
		for r in current_result:
			if r.type == "node" and r.id == current_node_id:
				main_node_display(r)


func main_node_display(node_data):
	find_node("NodeIdValueLabel").text = node_data.id
	var r_cloud = "n/a"
	var r_account = "n/a"
	var r_region = "n/a"
	if node_data.has("ancestors"):
		if node_data.ancestors.has("cloud"):
			r_cloud = node_data.ancestors.cloud.reported.name
		if node_data.ancestors.has("account"):
			r_account = node_data.ancestors.account.reported.name
			r_account = Utils.truncate_string(r_account, get_font("font"), 150.0)
		if node_data.ancestors.has("region"):
			r_region = node_data.ancestors.region.reported.name
	
	if node_data.has("reported"):
		if node_data.reported.has("ctime"):
			find_node("NodeCtimeLabel").show()
			find_node("NodeCtimeValueLabel").show()
			find_node("NodeCtimeValueLabel").text = node_data.reported.ctime
		else:
			find_node("NodeCtimeLabel").hide()
			find_node("NodeCtimeValueLabel").hide()
		
		if node_data.reported.has("age"):
			find_node("NodeAgeLabel").show()
			find_node("NodeAgeValueLabel").show()
			find_node("NodeAgeValueLabel").text = node_data.reported.age
		else:
			find_node("NodeAgeLabel").hide()
			find_node("NodeAgeValueLabel").hide()
		
		# Display node tags
		if node_data.reported.has("tags") and not node_data.reported.tags.empty():
			find_node("TagsGroup").show()
			var tags = find_node("TagsContent")
			for c in tags.get_children():
				c.queue_free()
			for tag in node_data.reported.tags:
				var new_tag_var = Label.new()
				new_tag_var.rect_min_size.x = 200
				var new_tag_value = Label.new()
				new_tag_var.text = tag
				new_tag_value.text = node_data.reported.tags[tag]
				tags.add_child(new_tag_var)
				tags.add_child(new_tag_value)
		else:
			find_node("TagsGroup").hide()
		
		# Display node ancestory / descendants
	
	var r_name = node_data.reported.name
	find_node("NodeNameLabel").text = r_name
	var r_kind = node_data.reported.kind
	find_node("NodeKindLabel").text = r_kind
	#new_result.get_node("VBox/ResultDetails").text = r_cloud + " > " + r_account + " > " + r_region
