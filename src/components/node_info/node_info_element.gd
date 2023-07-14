extends Control

signal node_shown(node_id)

var active_request :ResotoAPI.Request
var aggregation_request :ResotoAPI.Request
var current_node_id : String				= ""
var id_history : Array						= []
var current_main_node : Dictionary			= {}
var breadcrumbs : Array						= []
var treemap_display_mode : int				= 1
var last_aggregation_query	: String		= ""
var default_treemap_mode : int				= 1
var treemap_button_script_pressed : bool	= false
var treemap_button_force_switched : bool	= false

var successors_count := 0
var predecessors_count := 0
var page_size := 50
var treemap_format := {}

onready var n_icon_cleaned := $"%NodeIconCleaned"
onready var n_icon_phantom := $"%NodeIconPhantom"
onready var property_container := $"%PropertyContainer"
onready var tag_group := $"%TagsGroup"
onready var graph_a_star := GraphAStar.new()

# Resoto Action Buttons
onready var btn_protect_add : Button = $"%ProtectButton"
onready var btn_protect_remove : Button = $"%UnProtectButton"
onready var btn_cleanup_add : Button = $"%AddToCleanupButton"
onready var btn_cleanup_remove : Button = $"%RemoveFromCleanupButton"
onready var successors_spinner := $"%SuccessorsPageSpinner"
onready var predecessors_spinner := $"%PredecessorsPageSpinner"


func _ready():
	_g.connect("explore_node_by_id", self, "show_node")
	root_button.connect("pressed", self, "on_id_button_pressed", ["root"])


func show_node(node_id:String, _add_to_history:=true, view:="last"):
	if _g.resoto_model.empty():
		yield(_g, "model_loaded")
	if node_id != current_node_id:
		clear_view()
	# cancel the active request... this created problems with the signal returning old requests
	if active_request:
		active_request.cancel()
	if aggregation_request:
		aggregation_request.cancel()
	
	_g.content_manager.change_section_explore("node_single_info")
	var search_command = "id(\"" + node_id + "\") <-[0:]-"
	if _add_to_history and current_node_id != "" and current_node_id != node_id:
		id_history.append(current_node_id)
	current_node_id = node_id
	tag_group.node_id = current_node_id
	active_request = API.graph_search(search_command, self, "graph")
	
	$"%TreeMap".clear_treemap()
	
	clear_neighbourhood_view()
	
	for button in $"%NodeNavButtons".get_children():
		if button.text == view:
			select_nav_section(button)
			break


func get_selected_nav_section():
	var section := "last"
	for button in $"%NodeNavButtons".get_children():
		if button.pressed:
			section = button.text
			break
	return section


func clear_neighbourhood_view():
	for c in $"%NeigbourhoodViewContainer".get_children():
		c.queue_free()

const NeighbourhoodView = preload("res://components/neighbourhood/component_neighbourhood_view.tscn")
func create_neighbourhoodview(_node_id:String):
	clear_neighbourhood_view()
	
	var new_nhv = NeighbourhoodView.instance()
	$"%NeigbourhoodViewContainer".add_child(new_nhv)
	new_nhv.use_for_navigation = true
	new_nhv.main_node_id = _node_id
	new_nhv.graph_padding = Vector2(150, 50)
	new_nhv.connect("clicked_node", self, "navigate_from_neighbourhood")
	new_nhv.display_node(_node_id)


func navigate_from_neighbourhood(_node_id:String):
	show_node(_node_id)


func clear_view():
	# Clean old properties
	for c in property_container.get_children():
		c.queue_free()
	for c in breadcrumb_container.get_children():
		if c == root_button or c == res_list_btn:
			continue
		c.queue_free()
	tag_group.clear()
	$"%TreeMapModeButton".set_pressed_direct(false)
	$"%NodeNameLabel".set("custom_colors/font_color", Color.transparent)
	$"%KindLabelButton".set("custom_colors/font_color", Color.transparent)
	n_icon_cleaned.hide()


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			# Request was cancelled
			return
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		show()
		return
	
	if _response.transformed.has("result"):
		if _response.transformed.result is String and _response.transformed.result.begins_with("Error"):
			_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
			return
		
		var current_result = _response.transformed.result
		
		breadcrumbs = graph_a_star.get_shortest_path(current_result, "root", current_node_id)
		update_breadcrumbs()
		
		if not current_result.empty() and current_result[0].has("reported"):
			$"%AllDataGroup".node_text = Utils.readable_dict(current_result[0].reported)
		
		for r in current_result:
			if r.type == "node" and r.id == current_node_id:
				main_node_display(r)
				hide_treemap()
				treemap_display_mode = default_treemap_mode
				$"%TreeMapModeButton".disabled = false
				$"%TreeMapModeButton".modulate.a = 0.3
				if treemap_display_mode == 0:
					var descendants_query:= "aggregate(kind: sum(1) as count): id(\"%s\") -[1:]->" % str(current_node_id)
					last_aggregation_query = descendants_query
					aggregation_request = API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")

				elif treemap_display_mode == 1:
					if r.has("reported") and r.reported.has("kind"):
						var descendants_query:= "aggregate(/ancestors.%s.reported.name: sum(1) as count): /ancestors.%s.reported.id%s and /ancestors.%s.reported.name!=null"
						match r.reported.kind:
							"graph_root":
								descendants_query = descendants_query % ["cloud", "cloud", "!=null", "cloud"]
							"cloud":
								descendants_query = descendants_query % ["account", "cloud", "=\"" + r.reported.id + "\"", "account"]
							"account", "gcp_project", "aws_account", "digitalocean_team", "slack_team", "kubernetes_cluster", "onelogin_account":
								descendants_query = descendants_query % ["region", "account", "="+r.reported.id, "region"]
							"-":
								# not yet in use, this would eventually be neccessary for gcp
								descendants_query = descendants_query % ["zone", "region", "="+r.reported.id, "zone"]
							_:
								treemap_display_mode = 0
								$"%TreeMapModeButton".disabled = true
								descendants_query = "aggregate(kind: sum(1) as count): id(\"%s\") -[1:]->" % str(current_node_id)
						last_aggregation_query = descendants_query
						aggregation_request = API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")
					else:
						# use fallback
						pass
		show()
		emit_signal("node_shown", tag_group.node_id, get_selected_nav_section())
		
		if $"%SuccessorsPredecessorsButton".pressed:
			_on_SuccessorsPredecessorsButton_pressed()


func _on_get_descendants_query_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		show()
		return
	
	if _response.transformed.has("result"):
		if _response.transformed.result is String and _response.transformed.result.begins_with("Error"):
			_g.emit_signal("add_toast", "Error in Node Info", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
			return
		if not _response.transformed.result.empty():
			$"%TreeMapButton".disabled = false
			treemap_format = {}
			var key_name:String = _response.transformed.result[0]["group"].keys()[0]
			for element in _response.transformed.result:
				treemap_format[element.group[key_name]] = element.count
		else:
			if $"%TreeMapButton".pressed:
				select_nav_section($"%NeighbourhoodButton")
			$"%TreeMapButton".disabled = true
			
	show_nav_section()

func hide_treemap():
	find_node("TreeMap").hide()


func update_treemap(_treemap_content:Dictionary = {}):
	if _treemap_content.empty():
		return
	
	var account_dict:= {}
	for key in _treemap_content:
		account_dict[key] = _treemap_content[key]
	
	$"%TreeMapContainer".show()
	if treemap_display_mode != default_treemap_mode:
		$"%TreeMapModeButton".disabled = treemap_display_mode == 0
#		if treemap_display_mode == 0:
#			_g.emit_signal("add_toast", "View not available", "Node Successors by their Descendant Count is not available here.", 2, self, 1.5)
	$"%TreeMapModeButton".modulate.a = 1.0 if !$"%TreeMapModeButton".disabled else 0.0
	$"%TreeMapTitle".text = "Node Descendants grouped by Kind" if treemap_display_mode == 0 else "Node Successors by their Descendant Count"
	
	$"%TreeMap".clear_treemap()
	find_node("TreeMap").show()
	yield(VisualServer, "frame_post_draw")
	$"%TreeMap".create_treemap(account_dict)


onready var breadcrumb_container = find_node("BreadcrumbContainer")
onready var bc_button = find_node("BreadcrumbButton")
onready var root_button = find_node("RootButton")
onready var res_list_btn = find_node("ResourceListButton")
onready var bc_arrow = find_node("BreadcrumbArrow")
func update_breadcrumbs():
	for c in breadcrumb_container.get_children():
		if c == root_button or c == res_list_btn:
			continue
		c.queue_free()
	
	for b in breadcrumbs:
		if b.id == "root":
			continue
		var new_arrow = bc_arrow.duplicate()
		breadcrumb_container.add_child(new_arrow)
		var new_button = bc_button.duplicate()
		breadcrumb_container.add_child(new_button)
		new_button.text = b.reported.name
		new_button.hint_tooltip = b.reported.kind
		new_button.connect("pressed", self, "on_id_button_pressed", [b.id])
		
	breadcrumb_container.move_child(res_list_btn, breadcrumb_container.get_child_count())


func main_node_display(node_data):
	current_main_node = node_data
	
	# Clean old properties
	for c in property_container.get_children():
		c.queue_free()
	
	# Name (ID) and Kind
	var r_name = node_data.reported.name
	var r_id = node_data.reported.id if "id" in node_data.reported else "null"
	$"%NodeNameLabel".text = r_name if r_name == r_id else r_name + " (%s)" % r_id
	var r_kind = node_data.reported.kind
	$"%KindLabelButton".text = r_kind
	$"%IconContainer".setup(r_kind)
	
	# Reset Buttons
	$"%AddToCleanupButton".show()
	$"%RemoveFromCleanupButton".hide()
	
	$"%NodeNameLabel".set("custom_colors/font_color", null)
	$"%KindLabelButton".set("custom_colors/font_color", null)
	
	var has_meta:bool =  node_data.has("metadata")
	var has_reported:bool = node_data.has("reported")
	var has_desired:bool = node_data.has("desired")
	var has_tags:bool = false
	if has_reported and node_data.reported.has("tags"):
		has_tags = true
	
	if has_meta and node_data.metadata.has("cleaned"):
		n_icon_cleaned.visible = node_data.metadata.cleaned
	if has_meta and node_data.metadata.has("protected"):
		btn_protect_add.visible = !node_data.metadata.protected
		btn_protect_remove.visible = node_data.metadata.protected
	if has_meta and node_data.metadata.has("phantom"):
		n_icon_phantom.visible = node_data.metadata.phantom
	if has_desired and node_data.desired.has("clean"):
		btn_cleanup_add.visible = !node_data.desired.clean
		btn_cleanup_remove.visible = node_data.desired.clean
	
	var visible_properties:= {
		"kind" : ["Kind", "kind"],
		"name" : ["Name", "string"],
		"id" : ["Id", "string"],
		"age" : ["Age", "duration"],
		"last_update" : ["Last Update", "duration"],
		"last_access" : ["Last Access", "duration"],
		}
	
	if has_reported:
		for vp_key in visible_properties:
			if node_data.reported.has(vp_key):
				var descr_node:= Label.new()
				descr_node.text = visible_properties[vp_key][0]
				var value_node = load("res://components/elements/utility/clipped_label.tscn").instance()
				value_node.add_child(preload("res://components/shared/label_left_click_copy.tscn").instance())
				var value_text = str(node_data.reported[vp_key])
				
				if vp_key == "name":
					var id_txt = str(node_data.reported.id)
					if value_text == id_txt:
						descr_node.text += " (Id)"
				
				elif vp_key == "id":
					var name_txt = str(node_data.reported.name)
					if value_text == name_txt:
						continue
				
				if visible_properties[vp_key][1] == "duration":
					value_text = Utils.readable_duration(value_text)
				
				value_node.raw_text = value_text
				value_node.size_flags_horizontal = SIZE_EXPAND_FILL
				property_container.add_child(descr_node)
				property_container.add_child(value_node)
		
		# Handle Tags
		if has_tags:
			tag_group.clear()
			tag_group.create_tags(node_data.reported.tags)


func on_id_button_pressed(id:String) -> void:
	show_node(id)


func _on_TreeMap_pressed(click_meta:String) -> void:
	if treemap_display_mode == 0:
		# click_meta = kind
		_g.emit_signal("explore_node_list_data", current_main_node, click_meta)
		Analytics.event(Analytics.EventsExplore.EXPLORE_NODE_LIST, {"explore": "data"})
	elif treemap_display_mode == 1:
		# click_meta = id (not node id!)
		var search_query:= "id(\"%s\") --> name=\"%s\"" % [current_node_id, click_meta]
		API.graph_search(search_query, self, "list", "_on_get_node_from_id_done")


func _on_get_node_from_id_done(_error:int, _r:ResotoAPI.Response) -> void:
	if _error:
		return
	if _r.transformed.result:
		show_node(_r.transformed.result[0].id)

	
func _on_successors_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Node List", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	
	if _response.transformed.has("result"):
		show_data(_response.transformed.result, $"%SuccessorsContainer")
	
func _on_predecessors_search_done(error:int, _response:UserAgent.Response) -> void:		
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Node List", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	
	if _response.transformed.has("result"):
		show_data(_response.transformed.result, $"%PredecessorsContainer")
		
func show_data(result, parent_node):
	for r in result:
		var new_result = preload("res://components/fulltext_search_menu/full_text_search_result_template.tscn").instance()
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
				
		new_result.get_node("VBox/Top/ResultKind").text = r.reported.name
		new_result.get_node("VBox/Top/ResultName").text = r.reported.kind
		new_result.get_node("VBox/ResultDetails").text = ancestors
		
		new_result.connect("pressed", self, "show_node", [r.id, true])
		new_result.connect("pressed", self, "_on_NeighbourhoodButton_pressed")
		
		parent_node.add_child(new_result)


func _on_KindLabelButton_pressed():
	if current_main_node.reported.kind != null:
		_g.emit_signal("explore_node_list_kind", current_main_node.reported.kind)
		Analytics.event(Analytics.EventsExplore.EXPLORE_NODE_LIST, {"explore": "kind"})


func _on_NodeIDCopyButton_pressed():
	OS.set_clipboard(current_node_id)


func _on_TreeMap_pressed_lmb(clicked_element:Node) -> void:
	if treemap_display_mode == 0:
		# click_meta = kind
		_g.emit_signal("explore_node_list_data", current_main_node, clicked_element.element_name)
		Analytics.event(Analytics.EventsExplore.EXPLORE_NODE_LIST, {"explore": "data"})
	elif treemap_display_mode == 1:
		# click_meta = id (not node id!)
		var search_query:= "id(\"%s\") --> name=\"%s\"" % [current_node_id, clicked_element.element_name]
		API.graph_search(search_query, self, "list", "_on_get_node_from_id_done")


func _on_TreeMap_pressed_rmb(_clicked_element:Node):
	if id_history.empty():
		return
	var last_id = id_history[-1]
	id_history.pop_back()
	show_node(last_id, false)
	Analytics.event(Analytics.EventsExplore.BACK)


func _on_LeafPanel_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		_on_TreeMap_pressed_rmb(null)


func _on_TreeMapCopyButton_pressed():
	OS.set_clipboard(last_aggregation_query)
	Analytics.event(Analytics.EventsExplore.COPY_QUERY, {"query" : last_aggregation_query})


func _on_TreeMapModeButton_toggled(button_pressed:bool):
	if (default_treemap_mode == 1 and !button_pressed) or (default_treemap_mode == 0 and button_pressed):
		return
	
	default_treemap_mode = 1 if !button_pressed else 0
	$"%TreeMapTitle".text = "Node Descendants grouped by Kind" if default_treemap_mode == 0 else "Node Successors by their Descendant Count"
	show_node(current_node_id, false)
	Analytics.event(Analytics.EventsExplore.CHANGE_MODE, {"mode" : default_treemap_mode})


func _on_TagsGroup_tags_request_refresh():
	API.get_node_by_id(current_node_id, self, "_on_get_node_by_id_for_tags_done")


func _on_get_node_by_id_for_tags_done(_error:int, _r:ResotoAPI.Response) -> void:
	if _error:
		return
	tag_group.clear()
	var node_info = _r.transformed.result.reported.tags
	tag_group.create_tags(node_info)


func _on_ResourceListButton_pressed():
	_g.emit_signal("explore_node_list")
	Analytics.event(Analytics.EventsExplore.EXPLORE_NODE_LIST)


func _on_RemoveFromCleanupButton_pressed():
	btn_cleanup_remove.hide()
	btn_cleanup_add.show()
	var remove_from_cleanup_query : String = "search id(\"%s\") | set_desired clean=false" % [current_node_id]
	if not _g.ui_test_mode:
		API.cli_execute(remove_from_cleanup_query, self, "_on_remove_cleanup_query_done")
	else:
		print(remove_from_cleanup_query)
		
	Analytics.event(Analytics.EventsExplore.REMOVE_FROM_CLEANUP, {"query": remove_from_cleanup_query})


func _on_AddToCleanupButton_pressed():
	btn_cleanup_remove.show()
	btn_cleanup_add.hide()
	var cleanup_query : String = "search id(\"%s\") | clean" % [current_node_id]
	if not _g.ui_test_mode:
		API.cli_execute(cleanup_query, self, "_on_cleanup_query_done")
	else:
		print(cleanup_query)
		
	Analytics.event(Analytics.EventsExplore.ADD_TO_CLEANUP, {"query": cleanup_query})


func _on_ProtectButton_pressed():
	btn_protect_remove.show()
	btn_protect_add.hide()
	var protect_query : String = "search id(\"%s\") | set_metadata protected=true" % current_node_id
	if not _g.ui_test_mode:
		API.cli_execute(protect_query, self, "_on_protect_query_done")
	else:
		print(protect_query)
		
	Analytics.event(Analytics.EventsExplore.PROTECT, {"query": protect_query})


func _on_UnProtectButton_pressed():
	btn_protect_remove.hide()
	btn_protect_add.show()
	var protect_query : String = "search id(\"%s\") | set_metadata protected=false" % current_node_id
	if not _g.ui_test_mode:
		API.cli_execute(protect_query, self, "_on_protect_query_done")
	else:
		print(protect_query)
	Analytics.event(Analytics.EventsExplore.PROTECT, {"query": protect_query})


func _on_remove_cleanup_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return


func _on_protect_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return


func _on_cleanup_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return


func show_nav_section():
	if $"%TreeMapButton".pressed:
		update_treemap(treemap_format)
	elif $"%NeighbourhoodButton".pressed:
		create_neighbourhoodview(current_node_id)
	elif $"%AllDetailsButton".pressed:
		_on_AllDetailsButton_pressed()
	elif $"%SuccessorsPredecessorsButton".pressed():
		_on_SuccessorsPredecessorsButton_pressed()

func select_nav_section(button: Button):
	if not button.pressed:
		button.pressed = true
		button.emit_signal("pressed")

func _on_TreeMapButton_pressed():
	$"%TreeMapButton".pressed = true
	$"%NeighbourhoodButton".pressed = false
	$"%AllDetailsButton".pressed = false
	$"%SuccessorsPredecessorsButton".pressed = false
	$"%TreeMapContainer".show()
	$"%AllDataFullView".hide()
	$"%NeigbourhoodViewContainer".hide()
	$"%SuccessorsPredecessorsContainer".hide()
	update_treemap(treemap_format)
	emit_signal("node_shown", current_node_id, $"%TreeMapButton".text)


func _on_NeighbourhoodButton_pressed():
	$"%TreeMapButton".pressed = false
	$"%NeighbourhoodButton".pressed = true
	$"%AllDetailsButton".pressed = false
	$"%SuccessorsPredecessorsButton".pressed = false
	$"%TreeMapContainer".hide()
	$"%AllDataFullView".hide()
	$"%NeigbourhoodViewContainer".show()
	$"%SuccessorsPredecessorsContainer".hide()
	emit_signal("node_shown", current_node_id, $"%NeighbourhoodButton".text)

func _on_AllDetailsButton_pressed():
	$"%TreeMapButton".pressed = false
	$"%NeighbourhoodButton".pressed = false
	$"%AllDetailsButton".pressed = true
	$"%SuccessorsPredecessorsButton".pressed = false
	$"%AllDataFullView".show()
	$"%TreeMapContainer".hide()
	$"%NeigbourhoodViewContainer".hide()
	$"%SuccessorsPredecessorsContainer".hide()
	emit_signal("node_shown", current_node_id, $"%AllDetailsButton".text)


func _on_AllDataGroup_show_full_all_data():
	_on_AllDetailsButton_pressed()


func _on_SuccessorsPredecessorsButton_pressed():
	$"%TreeMapButton".pressed = false
	$"%NeighbourhoodButton".pressed = false
	$"%AllDetailsButton".pressed = false
	$"%SuccessorsPredecessorsButton".pressed = true
	$"%AllDataFullView".hide()
	$"%TreeMapContainer".hide()
	$"%NeigbourhoodViewContainer".hide()
	$"%SuccessorsPredecessorsContainer".show()
	
	emit_signal("node_shown", current_node_id, $"%SuccessorsPredecessorsButton".text)
	
	for child in $"%SuccessorsContainer".get_children():
		$"%SuccessorsContainer".remove_child(child)
		child.queue_free()
	
	for child in $"%PredecessorsContainer".get_children():
		$"%PredecessorsContainer".remove_child(child)
		child.queue_free()
	
	var search_command = "id(\"" + current_main_node.id + "\") -->" 
	API.cli_execute_json("search " + search_command + " | count", self, "cli_data", "_on_successors_count_done")
	
	search_command = "id(\"" + current_main_node.id + "\") -->" 
	API.cli_execute_json("search " + search_command + " | count", self, "cli_data", "_on_predecessors_count_done")
	
func _on_successors_count_done(_e, _r):
	if _e:
		successors_count = 0
	else:
		successors_count = int(_r.transformed.result[0].split(": ")[1])
	
	if successors_count > page_size:
		successors_spinner.show()
# warning-ignore:integer_division
		successors_spinner.max_value = ceil(float(successors_count) / page_size)
	else:
		successors_spinner.hide()
		
	successors_spinner.value = 1
	
func _on_predecessors_count_done(_e, _r):
	if _e:
		predecessors_count = 0
	else:
		predecessors_count = int(_r.transformed.result[0].split(" ")[1])
		
	if predecessors_count > page_size:
		predecessors_spinner.show()
# warning-ignore:integer_division
		predecessors_spinner.max_value = ceil(float(successors_count) / page_size)

	else:
		predecessors_spinner.hide()
		
	predecessors_spinner.value = 1
		
func cli_data(_e, _r):
	pass

func _on_PredecessorsPageSpinner_value_changed(value):
	if current_main_node.empty():
		return
	
	var search_command = "id(\"" + current_main_node.id + "\") <--"+ " limit %d, %d" % [page_size* (value-1), page_size]
	API.graph_search(search_command , self, "list", "_on_predecessors_search_done")


func _on_SuccessorsPageSpinner_value_changed(value):
	if current_main_node.empty():
		return
	
	var search_command = "id(\"" + current_main_node.id + "\") -->" 
	API.graph_search(search_command + " limit %d, %d" % [page_size * (value-1), page_size], self, "list", "_on_successors_search_done")


func _on_NeigbourhoodViewContainer_visibility_changed():
	if $"%NeigbourhoodViewContainer".visible and $"%NeigbourhoodViewContainer".get_child_count() == 0:
		create_neighbourhoodview(current_node_id)
		pass
