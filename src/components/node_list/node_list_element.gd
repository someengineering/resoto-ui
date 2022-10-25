extends MarginContainer

const NODE_LIMIT:int = 500

const SearchResult = preload("res://components/fulltext_search_menu/full_text_search_result_template.tscn")

var active_request:ResotoAPI.Request
var parent_node_id:String
var parent_node_name:String
var filter_variables:Dictionary

onready var parent_button = find_node("ParentNodeButton")
onready var list_kind_button = $"%ListKindButton"
onready var node_kind_button = $"%NodeKindButton"
onready var arrow_icon_mid = $"%ArrowIconMid"
onready var all_kinds_label = $"%AllKindsLabel"
onready var search_type_label = $"%SearchTypeLabel"
onready var kind_arrow = find_node("KindLabelArrow")
onready var template = find_node("ResultTemplate")
onready var scroll_container = $Margin/VBox/MainPanel/ScrollContainer/Content
onready var vbox = $Margin/VBox/MainPanel/ScrollContainer/Content/ListContainer


func _ready():
	_g.connect("explore_node_list_data", self, "show_kind_from_node_data")
	_g.connect("explore_node_list_from_node", self, "explore_node_list_from_node")
	_g.connect("explore_node_list_search", self, "show_list_from_search")
	_g.connect("explore_node_list_kind", self, "show_kind")
	_g.connect("explore_node_list_id", self, "show_kind_from_node_id")


func change_section_to_self():
	_g.content_manager.change_section_explore("node_list_info")


func show_kind_from_node_data(parent_node:Dictionary, kind:String):
	change_section_to_self()
	reset_display()
	var search_command = "id(\"" + parent_node.id + "\") -[1:]-> is(" + kind + ") limit " + str(NODE_LIMIT)
	
	search_type_label.hide()
	all_kinds_label.hide()
	arrow_icon_mid.show()
	node_kind_button.show()
	list_kind_button.show()
	
	node_kind_button.text = parent_node.reported.kind
	parent_node_id = parent_node.id
	parent_node_name = parent_node.reported.name
	
	parent_button.text = parent_node_name
	parent_button.set_meta("id", parent_node_id)
	parent_button.show()
	
	list_kind_button.text = kind
	
	active_request = API.graph_search(search_command, self, "list")


func show_kind(kind:String):
	change_section_to_self()
	var search_command = "is(" + kind + ") limit " + str(NODE_LIMIT)
	
	search_type_label.hide()
	list_kind_button.hide()
	arrow_icon_mid.hide()
	parent_button.hide()
	
	all_kinds_label.show()
	node_kind_button.show()
	node_kind_button.text = kind
	
	active_request = API.graph_search(search_command, self, "list")


func show_kind_from_node_id(id:String, kind:String):
	change_section_to_self()
	var search_command = "id(\"" + id + "\") -[1:]-> is(" + kind + ") limit " + str(NODE_LIMIT)
	parent_node_id = id
	
	search_type_label.hide()
	node_kind_button.hide()
	all_kinds_label.hide()
	arrow_icon_mid.show()
	list_kind_button.show()
	
	parent_button.text = parent_node_id
	parent_button.set_meta("id", parent_node_id)
	parent_button.show()
	
	list_kind_button.text = kind
	
	active_request = API.graph_search(search_command, self, "list")


func show_list_from_search(search_command:String):
	change_section_to_self()
	
	node_kind_button.hide()
	parent_button.hide()
	list_kind_button.hide()
	search_type_label.show()
	arrow_icon_mid.hide()
	
	search_type_label.text = "search " + search_command + " limit " + str(NODE_LIMIT)
	search_type_label.enabled = true
	
	active_request = API.graph_search(search_command, self, "list")


func explore_node_list_from_node(parent_node:Dictionary, search_command:String, kind_label_string:String):
	change_section_to_self()
	
	parent_node_id = parent_node.id
	parent_node_name = parent_node.reported.name
	
	node_kind_button.hide()
	parent_button.text = parent_node_name
	parent_button.set_meta("id", parent_node_id)
	parent_button.show()
	list_kind_button.hide()
	search_type_label.show()
	search_type_label.enabled = false
	arrow_icon_mid.show()
	
	if kind_label_string == "<--":
		search_type_label.text = "All Predecessors"
	elif kind_label_string == "-->":
		search_type_label.text = "All Successors"
	else:
		search_type_label.text = kind_label_string
	
	active_request = API.graph_search(search_command, self, "list")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Node List", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	
	if _response.transformed.has("result"):
		# Delete old results, prepare new container (fastest way to delete a lot of nodes)
		filter_variables = {}
		var current_result = _response.transformed.result
		for r in current_result:
			add_result_element(r, vbox)
		show()


func add_result_element(r, parent_element:Node):
	var filter_string = ""
	
	var new_result = SearchResult.instance()
	parent_element.add_child(new_result)
	new_result.connect("pressed", self, "_on_node_button_pressed", [r.id])
	new_result.name = r.id
	new_result.hint_tooltip = "id: " + r.id
	var ancestors:String = ""
	if r.has("ancestors"):
		if r.ancestors.has("cloud"):
			ancestors += r.ancestors.cloud.reported.name
		if r.ancestors.has("account"):
			var r_account = r.ancestors.account.reported.name
			r_account = Utils.truncate_string_px(r_account, 4, 150.0)
			ancestors += " > " + r_account
		if r.ancestors.has("region"):
			ancestors += " > " + r.ancestors.region.reported.name
		if r.ancestors.has("zone"):
			ancestors += " > " + r.ancestors.zone.reported.name
			
	filter_string += ancestors
	filter_string += r.id + r.reported.name + r.reported.kind
	
	var r_name = r.reported.name
	var r_kind = r.reported.kind
	
	filter_variables[r.id] = filter_string
	
	new_result.get_node("VBox/Top/ResultKind").text = r_kind
	new_result.get_node("VBox/Top/ResultName").text = r.id + " | " + r_name
	new_result.get_node("VBox/ResultDetails").text = ancestors


func filter_results(filter_string:String):
	if filter_string == "":
		for c in vbox.get_children():
			c.show()
		return
	
	for c in vbox.get_children():
		c.visible = filter_variables[c.name].find(filter_string) >= 0


func _on_ParentNodeButton_pressed():
	reset_display()
	_g.content_manager.change_section_explore("node_single_info")
	_g.content_manager.find_node("NodeSingleInfo").show_node(parent_node_id)


func _on_node_button_pressed(id:String):
	reset_display()
	_g.content_manager.change_section_explore("node_single_info")
	_g.content_manager.find_node("NodeSingleInfo").show_node(id)


func reset_display():
	hide()
	vbox.queue_free()
	vbox = VBoxContainer.new()
	scroll_container.add_child(vbox)
	$Margin/VBox/Filter/FilterLineEdit.text = ""


func _on_FullTextSearch_text_changed(new_text):
	filter_results(new_text)


func _on_NodeKindButton_pressed():
	show_kind(node_kind_button.text)


func _on_ListKindButton_pressed():
	show_kind(list_kind_button.text)


func _on_IconButton_pressed():
	reset_display()
	_g.content_manager.change_section_explore("node_single_info")
