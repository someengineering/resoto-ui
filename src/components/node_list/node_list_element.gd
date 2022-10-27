extends MarginContainer

const NODE_LIMIT:int = 200

const SearchResult = preload("res://components/fulltext_search_menu/full_text_search_result_template.tscn")

var active_request : ResotoAPI.Request
var parent_node_id : String
var parent_node_name : String
var filter_variables : Dictionary
var use_limit : bool					= true
var last_query : String					= ""
var last_search_type : String			= ""
var results_tag_keys : Dictionary		= {}
var filtered_tag_keys : Dictionary		= {}

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
onready var filter_edit = $Margin/VBox/Filter/FilterLineEdit
onready var limit_button = $Margin/VBox/TitleBar/LimitButton
onready var limit_label = $Margin/VBox/TitleBar/LimitLabel
onready var tags_group := $Margin/VBox/Filter/TagsGroup


func _ready():
	_g.connect("explore_node_list", self, "show_self")
	_g.connect("explore_node_list_data", self, "show_kind_from_node_data")
	_g.connect("explore_node_list_from_node", self, "explore_node_list_from_node")
	_g.connect("explore_node_list_search", self, "show_list_from_search")
	_g.connect("explore_node_list_kind", self, "show_kind")
	_g.connect("explore_node_list_id", self, "show_kind_from_node_id")


func change_section_to_self():
	$Margin/VBox/TitleBar/SearchQueryCopyButton.show()
	reset_display()
	_g.content_manager.change_section_explore("node_list_info")


func show_self():
	_g.content_manager.change_section_explore("node_list_info")


func show_kind_from_node_data(parent_node:Dictionary, kind:String):
	last_search_type = "show_kind_from_node_data"
	change_section_to_self()
	var search_command = "id(\"" + parent_node.id + "\") -[1:]-> is(" + kind + ")"
	last_query = search_command
	
	if use_limit:
		search_command +=  " limit " + str(NODE_LIMIT)
	
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
	last_search_type = "show_kind"
	change_section_to_self()
	var search_command = "is(" + kind + ")"
	last_query = search_command
	
	if use_limit:
		search_command +=  " limit " + str(NODE_LIMIT)
	
	search_type_label.hide()
	list_kind_button.hide()
	arrow_icon_mid.hide()
	parent_button.hide()
	
	all_kinds_label.show()
	node_kind_button.show()
	node_kind_button.text = kind
	
	active_request = API.graph_search(search_command, self, "list")


func show_kind_from_node_id(id:String, kind:String):
	last_search_type = "show_kind_from_node_id"
	change_section_to_self()
	var search_command = "id(\"" + id + "\") -[1:]-> is(" + kind + ")"
	last_query = search_command
	
	if use_limit:
		search_command +=  " limit " + str(NODE_LIMIT)
	
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
	last_search_type = "show_list_from_search"
	change_section_to_self()
	
	node_kind_button.hide()
	parent_button.hide()
	list_kind_button.hide()
	search_type_label.show()
	arrow_icon_mid.hide()
	
	last_query = search_command
	
	if " limit " in search_command:
		limit_button.disabled = true
		limit_button.modulate.a = 0.3
		limit_label.modulate.a = 0.3
	
	if use_limit and not " limit " in search_command:
		search_command +=  " limit " + str(NODE_LIMIT)
		
	search_type_label.text = "search " + search_command
	search_type_label.enabled = true
	
	active_request = API.graph_search(search_command, self, "list")


func explore_node_list_from_node(parent_node:Dictionary, search_command:String, kind_label_string:String):
	last_search_type = "explore_node_list_from_node"
	change_section_to_self()
	
	last_query = search_command
	
	if use_limit:
		search_command +=  " limit " + str(NODE_LIMIT)
	
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
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Node List", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	
	if _response.transformed.has("result"):
		# Delete old results, prepare new container (fastest way to delete a lot of nodes)
		filter_variables = {}
		var current_result = _response.transformed.result
		for r in current_result:
			add_result_element(r, vbox)
		if filter_edit.text != "":
			filter_results(filter_edit.text)
		show()


func add_result_element(r, parent_element:Node):
	var filter_string = ""
	
	var new_result = SearchResult.instance()
	parent_element.add_child(new_result)
	new_result.connect("pressed", self, "_on_node_button_pressed", [r.id])
	new_result.name = r.id
	new_result.node_id = r.id
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
	

	if r.has("metadata"):
		if r.metadata.has("cleaned"):
			new_result.is_cleaned = r.metadata.cleaned
		if r.metadata.has("protected"):
			new_result.is_protected = r.metadata.protected
		if r.metadata.has("phantom"):
			new_result.is_phantom = r.metadata.phantom
	if r.has("desired") and r.desired.has("clean"):
		new_result.is_desired_cleaned = r.desired.clean
	
	var r_name = r.reported.name
	var r_kind = r.reported.kind
	
	if r.reported.has("tags") and not r.reported.tags.empty():
		new_result.tag_keys = r.reported.tags.keys()
	
	filter_variables[r.id] = filter_string
	
	new_result.get_node("VBox/Top/ResultKind").text = r_kind
	new_result.get_node("VBox/Top/ResultName").text = r_name
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
	results_tag_keys = {}
	filtered_tag_keys = {}
	limit_button.disabled = false
	limit_button.modulate.a = 1.0
	limit_label.modulate.a = 1.0
	vbox.queue_free()
	vbox = VBoxContainer.new()
	scroll_container.add_child(vbox)
	filter_edit.text = ""


func _on_FullTextSearch_text_changed(new_text):
	filter_results(new_text)


func _on_NodeKindButton_pressed():
	show_kind(node_kind_button.text)


func _on_ListKindButton_pressed():
	show_kind(list_kind_button.text)


func _on_IconButton_pressed():
	_g.content_manager.change_section_explore("node_single_info")


func _on_LimitButton_toggled(_pressed:bool):
	if use_limit == _pressed:
		return
	use_limit = _pressed
	if last_query == "":
		return
	active_request.cancel(ERR_PRINTER_ON_FIRE)
	var search_command : String = last_query
	if use_limit:
		search_command +=  " limit " + str(NODE_LIMIT)
	if last_search_type == "show_list_from_search":
		search_type_label.text = search_command
	
	# clear results
	vbox.queue_free()
	vbox = VBoxContainer.new()
	scroll_container.add_child(vbox)
	
	active_request = API.graph_search(search_command, self, "list")


func _on_SearchQueryCopyButton_pressed():
	var query : String = last_query
	if use_limit and not " limit " in query:
		query +=  " limit " + str(NODE_LIMIT)
	OS.set_clipboard(query)


func _on_AddToCleanupButton_pressed():
	var cleanup_query : String = ""
	if filter_edit.text == "":
		cleanup_query = "search " + last_query + " | clean"
	else:
		var node_ids_to_clean : PoolStringArray = []
		for c in vbox.get_children():
			if c.visible:
				c.is_desired_cleaned = true
				node_ids_to_clean.append(c.node_id)
		cleanup_query = "json %s | clean" % JSON.print(node_ids_to_clean)
	if not _g.demo_mode:
		API.cli_execute(cleanup_query, self, "_on_cleanup_query_done")
	else:
		print(cleanup_query)


func _on_RemoveFromCleanupButton_pressed():
	var remove_from_cleanup_query : String = ""
	if filter_edit.text == "":
		remove_from_cleanup_query = "search " + last_query + " | clean"
	else:
		var node_ids_to_clean : PoolStringArray = []
		for c in vbox.get_children():
			if c.visible:
				c.is_desired_cleaned = false
				node_ids_to_clean.append(c.node_id)
		remove_from_cleanup_query = "json %s | set_desired clean=false" % JSON.print(node_ids_to_clean)
	if not _g.demo_mode:
		API.cli_execute(remove_from_cleanup_query, self, "_on_remove_cleanup_query_done")
	else:
		print(remove_from_cleanup_query)


func _on_remove_cleanup_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return


func _on_cleanup_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return


func _on_TagsGroup_delete_tags(_tag_variable:String):
	var delete_tag_query : String = "tag delete %s" % [_tag_variable]


func _on_TagsGroup_update_tags(_tag_variable:String, _tag_value:String):
	var change_tag_query : String = ""
	if _tag_value != "":
		change_tag_query = "search id(\"%s\") | tag update %s %s" % [_tag_variable, _tag_value]
	else:
		change_tag_query = "search id(\"%s\") | tag update %s" % [_tag_variable]


func _on_TagsGroup_request_all_tag_keys():
	var new_tag_keys : Dictionary = {}
	for c in vbox.get_children():
		if c.visible:
			for tk in c.tag_keys:
				new_tag_keys[tk] = null
	
	var sorted_keys : Array = []
	for tk in new_tag_keys.keys():
		sorted_keys.append([tk, tk.to_lower()])
	sorted_keys.sort_custom(self, "sort_tag_keys")
	
	tags_group.tag_keys = []
	for tag_pair in sorted_keys:
		tags_group.tag_keys.append(tag_pair[0])


static func sort_tag_keys(a, b) -> bool:
	return a[1] < b[1]
