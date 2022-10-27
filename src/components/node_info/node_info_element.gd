extends Control

var active_request :ResotoAPI.Request
var aggregation_request :ResotoAPI.Request
var current_node_id : String				= ""
var id_history : Array						= []
var current_main_node : Dictionary			= {}
var breadcrumbs : Dictionary				= {}
var treemap_display_mode : int				= 1
var last_aggregation_query	: String		= ""
var default_treemap_mode : int				= 1
var treemap_button_script_pressed : bool	= false
var treemap_button_force_switched : bool	= false

onready var n_icon_protected := $Margin/VBox/NodeContent/NodeDetails/NodeBaseInfo/VBox/PropertyTitle/NodeIconProtected
onready var n_icon_cleaned := $Margin/VBox/NodeContent/NodeDetails/NodeBaseInfo/VBox/PropertyTitle/NodeIconCleaned
onready var n_icon_dclean := $Margin/VBox/NodeContent/NodeDetails/NodeBaseInfo/VBox/PropertyTitle/NodeIconDesiredClean
onready var n_icon_phantom := $Margin/VBox/NodeContent/NodeDetails/NodeBaseInfo/VBox/PropertyTitle/NodeIconPhantom
onready var property_container := $"%PropertyContainer"
onready var leaf_panel := $Margin/VBox/NodeContent/LeafPanel
onready var tag_group := $"%TagsGroup"


func _ready():
	Style.add($Margin/VBox/TitleBar/NodeIcon, Style.c.LIGHT)
	_g.connect("explore_node_by_id", self, "show_node")


func show_node(node_id:String, _add_to_history:=true):
	if node_id != current_node_id:
		clear_view()
	# cancel the active request... this created problems with the signal returning old requests
	if active_request:
		active_request.cancel(ERR_PRINTER_ON_FIRE)
	if aggregation_request:
		aggregation_request.cancel(ERR_PRINTER_ON_FIRE)
	
	_g.content_manager.change_section_explore("node_single_info")
	var search_command = "id(\"" + node_id + "\") <-[0:]-"
	if _add_to_history and current_node_id != "" and current_node_id != node_id:
		id_history.append(current_node_id)
	current_node_id = node_id
	tag_group.node_id = current_node_id
	active_request = API.graph_search(search_command, self, "graph")


func clear_view():
	# Clean old properties
	for c in property_container.get_children():
		c.queue_free()
	for c in breadcrumb_container.get_children():
		c.queue_free()
	tag_group.clear()
	$"%TreeMapModeButton".set_pressed_direct(false)
	$"%NodeNameLabel".text = "..."
	$"%KindLabelButton".text = "..."
	set_successor_button(false)
	set_predecessor_button(false)
	n_icon_protected.hide()
	n_icon_cleaned.hide()
	n_icon_dclean.hide()
	leaf_panel.hide()
	$"%TreeMapContainer".show()


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
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
		
		var current_result = _response.transformed.result
		
		if not current_result.empty() and current_result[0].has("reported"):
			$"%AllDataGroup".node_text = Utils.readable_dict(current_result[0].reported)
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
					set_predecessor_button(true)
					hide_treemap()
					treemap_display_mode = default_treemap_mode
					$"%TreeMapModeButton".disabled = false
					$"%TreeMapModeButton".modulate.a = 0.3
					# Not used anymore at the moment
					if treemap_display_mode == 0:
						var descendants_query:= "aggregate(kind: sum(1) as count): id(\"%s\") -[1:]->" % str(current_node_id)
						last_aggregation_query = descendants_query
						if r.id != "root":
	#						if (r.has("metadata") and r.metadata.has("descendant_summary")):
	#							update_treemap(r.metadata.descendant_summary)
	#						else:
							aggregation_request = API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")
						else:
							aggregation_request = API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")
							set_predecessor_button(false)
							set_successor_button(true)
					elif treemap_display_mode == 1:
						if r.has("reported") and r.reported.has("kind"):
							var descendants_query:= "aggregate(/ancestors.%s.reported.name: sum(1) as count): /ancestors.%s.reported.id%s and /ancestors.%s.reported.name!=null"
							match r.reported.kind:
								"graph_root":
									set_predecessor_button(false)
									set_successor_button(true)
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
		update_breadcrumbs()
		show()


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
			var treemap_format:= {}
			var key_name:String = _response.transformed.result[0]["group"].keys()[0]
			for element in _response.transformed.result:
				treemap_format[element.group[key_name]] = element.count
			update_treemap(treemap_format)
		else:
			$"%TreeMapContainer".hide()
			leaf_panel.show()


func hide_treemap():
	find_node("TreeMap").hide()


func update_treemap(_treemap_content:Dictionary = {}):
	if _treemap_content.empty():
		return
	set_successor_button(true)
	
	var account_dict:= {}
	for key in _treemap_content:
		account_dict[key] = _treemap_content[key]
	
	leaf_panel.hide()
	$"%TreeMapContainer".show()
	if treemap_display_mode != default_treemap_mode:
		$"%TreeMapModeButton".disabled = treemap_display_mode == 0
#		if treemap_display_mode == 0:
#			_g.emit_signal("add_toast", "View not available", "Node Successors by their Descendant Count is not available here.", 2, self, 1.5)
	$"%TreeMapModeButton".modulate.a = 1.0 if !$"%TreeMapModeButton".disabled else 0.0
	$"%TreeMapTitle".text = "Node Descendants grouped by Kind" if treemap_display_mode == 0 else "Node Successors by their Descendant Count"
	yield(VisualServer, "frame_post_draw")
	$"%TreeMap".clear_treemap()
	$"%TreeMap".create_treemap(account_dict)
	find_node("TreeMap").show()


func set_successor_button(_enabled:bool):
	$"%SuccessorsButton".disabled = !_enabled
	$"%SuccessorsButton".modulate.a = 1 if _enabled else 0


func set_predecessor_button(_enabled:bool):
	$"%PredecessorsButton".disabled = !_enabled
	$"%PredecessorsButton".modulate.a = 1 if _enabled else 0


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
	
	# Clean old properties
	for c in property_container.get_children():
		c.queue_free()
	
	# Name (ID) and Kind
	var r_name = node_data.reported.name
	var r_id = node_data.reported.id
	$"%NodeNameLabel".text = r_name if r_name == r_id else r_name + " (%s)" % r_id
	var r_kind = node_data.reported.kind
	$"%KindLabelButton".text = r_kind
	
	var has_meta:bool =  node_data.has("metadata")
	var has_reported:bool = node_data.has("reported")
	var has_desired:bool = node_data.has("desired")
	var has_tags:bool = false
	if has_reported and node_data.reported.has("tags"):
		has_tags = true
	
	if has_meta and node_data.metadata.has("cleaned"):
		n_icon_cleaned.visible = node_data.metadata.cleaned
	if has_meta and node_data.metadata.has("protected"):
		n_icon_protected.visible = node_data.metadata.protected
	if has_meta and node_data.metadata.has("phantom"):
		n_icon_phantom.visible = node_data.metadata.phantom
	if has_desired and node_data.desired.has("clean"):
		n_icon_dclean.visible = node_data.desired.clean
	
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
				value_node.script = load("res://components/elements/utility/clipped_label_copy_lmb.gd")
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
	elif treemap_display_mode == 1:
		# click_meta = id (not node id!)
		var search_query:= "id(\"%s\") --> name=\"%s\"" % [current_node_id, click_meta]
		API.graph_search(search_query, self, "list", "_on_get_node_from_id_done")


func _on_get_node_from_id_done(_error:int, _r:ResotoAPI.Response) -> void:
	if _error:
		return
	if _r.transformed.result:
		show_node(_r.transformed.result[0].id)


func _on_PredecessorsButton_pressed():
	var search_command = "id(\"" + current_main_node.id + "\") <-- limit 500"
	_g.emit_signal("explore_node_list_from_node", current_main_node, search_command, "<--")


func _on_SuccessorsButton_pressed():
	var search_command = "id(\"" + current_main_node.id + "\") --> limit 500"
	_g.emit_signal("explore_node_list_from_node", current_main_node, search_command, "-->")


func _on_KindLabelButton_pressed():
	_g.emit_signal("explore_node_list_kind", current_main_node.reported.kind)


func _on_NodeIDCopyButton_pressed():
	OS.set_clipboard(current_node_id)


func _on_TreeMap_pressed_lmb(clicked_element:Node) -> void:
	if treemap_display_mode == 0:
		# click_meta = kind
		_g.emit_signal("explore_node_list_data", current_main_node, clicked_element.element_name)
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


func _on_LeafPanel_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		_on_TreeMap_pressed_rmb(null)


func _on_TreeMapCopyButton_pressed():
	OS.set_clipboard(last_aggregation_query)


func _on_TreeMapModeButton_toggled(button_pressed:bool):
	if (default_treemap_mode == 1 and !button_pressed) or (default_treemap_mode == 0 and button_pressed):
		return
	
	default_treemap_mode = 1 if !button_pressed else 0
	$"%TreeMapTitle".text = "Node Descendants grouped by Kind" if default_treemap_mode == 0 else "Node Successors by their Descendant Count"
	show_node(current_node_id, false)


func _on_TagsGroup_tags_request_refresh():
	API.get_node_by_id(current_node_id, self, "_on_get_node_by_id_for_tags_done")


func _on_get_node_by_id_for_tags_done(_error:int, _r:ResotoAPI.Response) -> void:
	if _error:
		return
	tag_group.clear()
	var node_info = _r.transformed.result.reported.tags
	tag_group.create_tags(node_info)
