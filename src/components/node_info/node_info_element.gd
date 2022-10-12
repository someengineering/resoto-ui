extends Control

var active_request:ResotoAPI.Request
var current_node_id:String
var current_main_node:Dictionary
var breadcrumbs:Dictionary


func _ready():
	Style.add($Margin/VBox/TitleBar/NodeIcon, Style.c.LIGHT)


func show_node(node_id:String):
	var search_command = "id(" + node_id + ") <-[0:]-"
	current_node_id = node_id
	
	print(search_command)
	active_request = API.graph_search(search_command, self, "graph")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		var current_result = _response.transformed.result
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
					update_treemap(r)
		update_breadcrumbs()


func update_treemap(r):
	find_node("TreeMapContainer").hide()
	if (not r.has("metadata") or not r.metadata.has("descendant_summary")):
		return
	
	var account_dict:= {}
	for key in r.metadata.descendant_summary:
		account_dict[key] = r.metadata.descendant_summary[key]
	
	find_node("TreeMapContainer").show()
	yield(VisualServer, "frame_post_draw")
	find_node("TreeMap").clear_treemap()
	find_node("TreeMap").create_treemap(account_dict)


onready var breadcrumb_container = find_node("BreadcrumbContainer")
onready var bc_button = find_node("BreadcrumbButton")
onready var bc_arrow = find_node("BreadcrumbArrow")
func update_breadcrumbs():
	for c in breadcrumb_container.get_children():
		c.queue_free()
	
	var next:String = "root"
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
				if not breadcrumbs.edges.empty():
					var new_arrow = bc_arrow.duplicate()
					breadcrumb_container.add_child(new_arrow)
		if not found_result:
			break


func main_node_display(node_data):
	current_main_node = node_data
	find_node("NodeIdValueLabel").text = node_data.id
	
	if node_data.has("metadata") and node_data.metadata.has("descendant_count"):
		find_node("NodeDescendantCountLabel").show()
		find_node("NodeDescendantCountValueLabel").show()
		find_node("NodeDescendantCountValueLabel").text = str(node_data.metadata.descendant_count)
	else:
		find_node("NodeDescendantCountLabel").hide()
		find_node("NodeDescendantCountValueLabel").hide()
	
	if node_data.has("reported"):
		if node_data.reported.has("ctime"):
			find_node("NodeCtimeLabel").show()
			find_node("NodeCtimeValueLabel").show()
			var time_str = node_data.reported.ctime.split("T")
			find_node("NodeCtimeValueLabel").text = time_str[0] + " - " + time_str[1].replace("Z", "")
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


func on_id_button_pressed(id:String):
	show_node(id)


func _on_TreeMap_pressed(kind:String):
	_g.content_manager.change_section("node_list_info")
	_g.content_manager.find_node("NodeListElement").show_kind_from_node_data(current_main_node, kind)


func _on_AncestorsButton_pressed():
	_g.content_manager.change_section("node_list_info")
	var search_command = "id(" + current_main_node.id + ") <-- limit 500"
	_g.content_manager.find_node("NodeListElement").show_list_from_search(current_main_node, search_command, "<--")


func _on_DescendantsButton_pressed():
	_g.content_manager.change_section("node_list_info")
	var search_command = "id(" + current_main_node.id + ") --> limit 500"
	_g.content_manager.find_node("NodeListElement").show_list_from_search(current_main_node, search_command, "-->")
