extends Control

var active_request:ResotoAPI.Request
var current_node_id:String = ""
var current_main_node:Dictionary = {}
var breadcrumbs:Dictionary = {}


func _ready():
	Style.add($Margin/VBox/TitleBar/NodeIcon, Style.c.LIGHT)


func show_node(node_id:String):
	hide()
	var search_command = "id(" + node_id + ") <-[0:]-"
	current_node_id = node_id
	active_request = API.graph_search(search_command, self, "graph")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		show()
		return
	if _response.transformed.has("result"):
		if _response.transformed.result is String and _response.transformed.result.begins_with("Error"):
			_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
			return
		
		var current_result = _response.transformed.result
		if not current_result.empty() and current_result[0].has("reported"):
			$"%AllDataTextEdit".text = Utils.readable_dict(current_result[0].reported)
		breadcrumbs.clear()
		breadcrumbs["edges"] = []
		breadcrumbs["nodes"] = {}
		for r in current_result:
			if r.type == "edge":
				breadcrumbs.edges.append(r)
			
			if r.type == "node":
				breadcrumbs.nodes[r.id] = (r)
				
				if r.id == current_node_id:
					main_node_display(r)
					set_successor_button(false)
					hide_treemap()
					if r.id != "root":
						if (r.has("metadata") and r.metadata.has("descendant_summary")):
							update_treemap(r.metadata.descendant_summary)
						else:
							var descendants_query:= "aggregate(kind: sum(1) as count): id(%s) -[1:]->" % str(current_node_id)
							API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")
					else:
						set_successor_button(true)
		update_breadcrumbs()
		show()


func _on_get_descendants_query_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		show()
		return
	if _response.transformed.has("result"):
		if _response.transformed.result is String and _response.transformed.result.begins_with("Error"):
			_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
			return
		if not _response.transformed.result.empty():
			var treemap_format:= {}
			for element in _response.transformed.result:
				treemap_format[element.group.kind] = element.count
			update_treemap(treemap_format)


func hide_treemap():
	find_node("TreeMapContainer").hide()


func update_treemap(_descendants:Dictionary = {}):
	if _descendants.empty():
		return
	
	set_successor_button(true)
	
	var account_dict:= {}
	for key in _descendants:
		account_dict[key] = _descendants[key]
	
	find_node("TreeMapContainer").show()
	yield(VisualServer, "frame_post_draw")
	find_node("TreeMap").clear_treemap()
	find_node("TreeMap").create_treemap(account_dict)


func set_successor_button(_enabled:bool):
	$"%SuccessorsButton".disabled = !_enabled
	$"%SuccessorsButton".modulate.a = 1 if _enabled else 0


onready var breadcrumb_container = find_node("BreadcrumbContainer")
onready var bc_button = find_node("BreadcrumbButton")
onready var root_button = find_node("RootButton")
onready var bc_arrow = find_node("BreadcrumbArrow")
func update_breadcrumbs():
	for c in breadcrumb_container.get_children():
		c.queue_free()
	
	var next:String = "root"
	
	
	var new_root_button = root_button.duplicate()
	breadcrumb_container.add_child(new_root_button)
	new_root_button.hint_tooltip = "Root"
	new_root_button.connect("pressed", self, "on_id_button_pressed", ["root"])
	
	if breadcrumbs.edges.size() > 0:
		var root_arrow = bc_arrow.duplicate()
		breadcrumb_container.add_child(root_arrow)
	
	while breadcrumbs.edges.size() > 0:
		var found_result:bool = false
		
		for e in breadcrumbs.edges:
			if e.from == next:
				found_result = true
				next = e.to
				var new_button = bc_button.duplicate()
				breadcrumb_container.add_child(new_button)
				new_button.text = breadcrumbs.nodes[next].reported.name
				new_button.hint_tooltip = breadcrumbs.nodes[next].reported.kind
				new_button.connect("pressed", self, "on_id_button_pressed", [breadcrumbs.nodes[next].id])
				breadcrumbs.edges.erase(e)
				
				if breadcrumbs.nodes[next].id == current_node_id:
					continue
				
				if not breadcrumbs.edges.empty():
					var new_arrow = bc_arrow.duplicate()
					breadcrumb_container.add_child(new_arrow)
		if not found_result:
			break


func main_node_display(node_data):
	current_main_node = node_data
	$"%NodeIdValueLabel".text = node_data.id
	
	if node_data.has("metadata") and node_data.metadata.has("descendant_count"):
		$"%NodeDescendantCountLabel".show()
		$"%NodeDescendantCountValueLabel".show()
		$"%NodeDescendantCountValueLabel".text = str(node_data.metadata.descendant_count)
	else:
		$"%NodeDescendantCountLabel".hide()
		$"%NodeDescendantCountValueLabel".hide()
	
	if node_data.has("reported"):
		if node_data.reported.has("ctime"):
			$"%NodeCtimeLabel".show()
			$"%NodeCtimeValueLabel".show()
			var time_str = node_data.reported.ctime.split("T")
			$"%NodeCtimeValueLabel".text = time_str[0] + " - " + time_str[1].replace("Z", "")
		else:
			$"%NodeCtimeLabel".hide()
			$"%NodeCtimeValueLabel".hide()
		
		if node_data.reported.has("age"):
			$"%NodeAgeLabel".show()
			$"%NodeAgeValueLabel".show()
			$"%NodeAgeValueLabel".text = node_data.reported.age
		else:
			$"%NodeAgeLabel".hide()
			$"%NodeAgeValueLabel".hide()
		
		
		# Display node tags
		if node_data.reported.has("tags") and not node_data.reported.tags.empty():
			$"%TagsGroup".show()
			var tags = $"%TagsContent"
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
			$"%TagsGroup".hide()
		
		# Display node ancestory / descendants
	
	var r_name = node_data.reported.name
	$"%NodeNameLabel".text = r_name
	var r_kind = node_data.reported.kind
	$"%KindLabelButton".text = r_kind


func on_id_button_pressed(id:String):
	show_node(id)


func _on_TreeMap_pressed(kind:String):
	_g.content_manager.change_section("node_list_info")
	_g.content_manager.find_node("NodeListElement").show_kind_from_node_data(current_main_node, kind)


func _on_PredecessorsButton_pressed():
	_g.content_manager.change_section("node_list_info")
	var search_command = "id(" + current_main_node.id + ") <-- limit 500"
	_g.content_manager.find_node("NodeListElement").show_list_from_search(current_main_node, search_command, "<--")


func _on_SuccessorsButton_pressed():
	_g.content_manager.change_section("node_list_info")
	var search_command = "id(" + current_main_node.id + ") --> limit 500"
	_g.content_manager.find_node("NodeListElement").show_list_from_search(current_main_node, search_command, "-->")


func _on_AllDataMaximizeButton_pressed():
	$AllDataPopup.show_all_data_popup($"%AllDataTextEdit".text, $"%AllDataTextEdit".scroll_vertical)


func _on_AllDataCopyButton_pressed():
	OS.set_clipboard($"%AllDataTextEdit".text)


func _on_KindLabelButton_pressed():
	_g.content_manager.change_section("node_list_info")
	_g.content_manager.find_node("NodeListElement").show_kind(current_main_node.reported.kind)


func _on_AllDataPopup_change_scroll_pos(_sv:int):
	$"%AllDataTextEdit".scroll_vertical = _sv
