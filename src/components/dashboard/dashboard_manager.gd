class_name DashboardManager
extends TabContainer

const DashboardContainerScene := preload("res://components/dashboard/dashboard_container.tscn")
const DashboardContainerPlaceholderScene := preload("res://components/dashboard/dashboard_container_placeholder.tscn")

signal all_dashboards_loaded
signal dashboard_saved
signal dashboard_opened(dashboard_name)
signal dashboard_deleted

const DefaultDashboardName:= "Resoto Example Dashboard"
const number_keys : Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

var available_dashboards : Dictionary = {}
var total_saved_dashboards : int = 0
var dashboards_loaded : int = 0
var default_dashboard_found:= false
var inform_dashboard_selected := true
var is_saving := false

onready var open_dashboard_btn = $"%OpenDashboard"
onready var del_dashboard_btn = $"%DeleteDashboard"
onready var dupe_dashboard_btn = $"%DuplicateDashboard"
onready var dashboards_list = find_node("DashboardItemList")
onready var manager_tab = $ManageDashboards


func _ready():
	set_tab_title(0, "Manage Dashboards")
	set_tab_icon(0, load("res://assets/icons/icon_small_dashboard.svg"))
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	connect("all_dashboards_loaded", self, "open_user_dashboards", [], CONNECT_ONESHOT)


func _unhandled_input(event):
	if event is InputEventKey and event.alt and event.is_pressed():
		if event.scancode == KEY_LEFT:
			current_tab = wrapi(current_tab - 1, 0, get_child_count() - 1)
		elif event.scancode == KEY_RIGHT:
			current_tab = wrapi(current_tab + 1, 0, get_child_count() - 1)
		elif event.scancode in number_keys:
			current_tab = int(min(number_keys.find(event.scancode), get_child_count() - 2))


func add_dashboard(dashboard_name : String = ""):
	var new_tab = DashboardContainerScene.instance()
	if dashboard_name != "":
		new_tab.dashboard_name = dashboard_name
	else:
		var new_name = "New_Dashboard"
		var names:= []
		for c in get_children():
			names.append(c.name.to_lower().replace(" ", "_"))
		
		if names.has(new_name.to_lower()):
			var new_number := 1
			while names.has(new_name.to_lower() + "_" +  str(new_number)):
				new_number += 1
			new_tab.dashboard_name = new_name + "_" +  str(new_number)
			new_tab.name = (new_name + "_" +  str(new_number)).replace("_", " ")
		else:
			new_tab.dashboard_name = new_name
			new_tab.name = new_name.replace("_", " ")

	new_tab.connect("deleted", self, "_on_tab_deleted")
	add_child(new_tab, true)
	move_child(new_tab, get_tab_control(current_tab).get_position_in_parent())
	
	new_tab.connect("dashboard_changed", self, "save_dashboard")
	new_tab.connect("dashboard_maximized", self, "maximize_dashboard")
	new_tab.connect("dashboard_closed", self, "close_dashboard")
	
	yield(VisualServer,"frame_post_draw")
	new_tab.dashboard._on_Grid_resized()


func _on_tab_deleted(tab:int, _db_last_saved_name:String, change_tab:=true) -> void:
	API.delete_config_id(self, get_db_config_name(_db_last_saved_name))
	if tab != -1 and change_tab and tab > 0:
		current_tab = tab-1
	if get_child_count() <= 2:
		request_saved_dashboards()


func maximize_dashboard(is_maximized:bool) -> void:
	tabs_visible = !is_maximized
	_g.emit_signal("fullscreen_hide_menu", is_maximized)
	if is_maximized:
		add_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		remove_stylebox_override("panel")


func _on_delete_config_id_done(_error: int, _response):
	if _error:
		return
	emit_signal("dashboard_deleted")


func save_dashboard(dashboard : DashboardContainer):
	if is_saving:
		return
	is_saving = true
	var data = dashboard.get_data()
	var old_name = dashboard.name
	var old_dashboard_name = dashboard.dashboard_name
	if dashboard.last_saved_name != DefaultDashboardName:
		API.delete_config_id(self, get_db_config_name(dashboard.last_saved_name))
		available_dashboards.erase(dashboard.last_saved_name.replace(" ", "_"))
		yield(self, "dashboard_deleted")
	API.patch_config_id(self, get_db_config_name(old_name), JSON.print(data))
	dashboard.last_saved_name = old_dashboard_name
	available_dashboards[old_dashboard_name.replace(" ", "_")] = data


func get_db_config_name(_name:String):
	return _g.dashboard_config_prefix + _name.replace(" ", "_")


func close_dashboard(dashboard : DashboardContainer):
	if is_saving:
		yield(self, "dashboard_saved")
	dashboard.connect("tree_exited", self, "_on_DashBoardManager_tab_changed", [], CONNECT_ONESHOT)
	dashboard.queue_free()
	save_opened_dashboards()


func _on_patch_config_id_done(_error : int, _response):
	# Removed the "success" toast as it was more confusing than helpful...
#	_g.emit_signal("add_toast", "Dashboard saved!", "", 0, self, 0.7)
	_g.emit_signal("toast_show_saved")
	emit_signal("dashboard_saved")
	is_saving = false
	_refresh_dashboard_list()


func request_saved_dashboards() -> void:
	API.get_configs(self)
	

func _on_get_configs_done(_error: int, response):
	default_dashboard_found = false
	available_dashboards.clear()
	total_saved_dashboards = 0
	for config in response.transformed.result:
		config = config as String
		if config.begins_with("resoto.ui.dashboard"):
			API.get_config_id(self, config)
			total_saved_dashboards += 1
	if total_saved_dashboards == 0:
		restore_default_dashboard()


func _on_get_config_id_done(_error : int, _response, _config):
	var dashboard = _response.transformed.result
	if dashboard is Dictionary:
		if not default_dashboard_found and dashboard.dashboard_name == DefaultDashboardName:
			default_dashboard_found = true
		available_dashboards[dashboard.dashboard_name.replace(" ", "_")] = dashboard
		dashboards_loaded += 1
		if dashboards_loaded >= total_saved_dashboards:
			if not default_dashboard_found:
				restore_default_dashboard()
			else:
				emit_signal("all_dashboards_loaded")
				_refresh_dashboard_list()


func restore_default_dashboard() -> void:
	var dashboard = Utils.load_json("res://data/resoto_example_dashboard.json")
	if not dashboard.empty():
		API.patch_config_id(self, get_db_config_name(dashboard.dashboard_name), JSON.print(dashboard))
		available_dashboards[dashboard.dashboard_name.replace(" ", "_")] = dashboard
	_refresh_dashboard_list()


func open_user_dashboards():
	inform_dashboard_selected = false
	var dashboard_status = get_user_dashboards()
	var open_dashboards : Array = dashboard_status.open_dashboards
	open_dashboards.invert()
	for dashboard in open_dashboards:
		if not available_dashboards.keys().has(dashboard):
			continue
		if dashboard_status.has("active_dashboard") and dashboard == dashboard_status.active_dashboard:
			load_dashboard(dashboard)
		else:
			add_dashboard_placeholder(dashboard)
	
	inform_dashboard_selected = true
	for i in get_children().size():
		if get_tab_control(i).name.replace(" ","_") == dashboard_status.active_dashboard:
			set_current_tab(i)


func load_dashboard(dashboard_name : String):
	if dashboard_name == "ManageDashboards":
		set_current_tab(get_children().find(manager_tab))
		return
	if not available_dashboards.has(dashboard_name):
		return
	var data : Dictionary = available_dashboards[dashboard_name]
	create_dashboard_with_data(data, false)


func add_dashboard_placeholder(dashboard_name : String):
	var dashboard_placeholder = DashboardContainerPlaceholderScene.instance()
	dashboard_placeholder.last_saved_name = dashboard_name
	dashboard_placeholder.dashboard_name = dashboard_name
	dashboard_placeholder.name = dashboard_name.replace("_", " ")
	add_child(dashboard_placeholder, true)
	move_child(dashboard_placeholder, get_tab_control(current_tab).get_position_in_parent())


var import_rename_new_name := ""
func import_dashboard_from_data(data):
	if not data.has("dashboard_name"):
		return
	
	import_rename_new_name = ""
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Name imported dashboard",
		"Enter a name for the imported dashboard:\n`%s`" % data.dashboard_name,
		data.dashboard_name + " import-" + str(OS.get_unix_time()),
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_import_rename_confirm_response", [data], CONNECT_ONESHOT)


func _on_import_rename_confirm_response(_button_clicked:String, _value:String, data:Dictionary):
	if _button_clicked == "left":
		if data.dashboard_name == _value:
			# No name change happened
			return
		# Check if a config with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		request_saved_dashboards()
		yield(self, "all_dashboards_loaded")
		if available_dashboards.has(_value.replace(" ", "_")):
			_g.emit_signal("add_toast", "Import failed", "A dashboard with that name already exists.", 1, self)
			return
		
		rename_new_name = _value
		data.dashboard_name = rename_new_name.replace("_", " ")
		API.put_config_id(self, get_db_config_name(rename_new_name), JSON.print(data))


func create_dashboard_with_data(data, save_dashboard:bool=true):
	if not data.has("dashboard_name"):
		return

	var dashboard_name = data.dashboard_name
	var dashboard = get_node_or_null(dashboard_name)
	if dashboard != null:
		current_tab = get_children().find(dashboard)
		return
		
	add_dashboard(dashboard_name)
	dashboard = get_node(dashboard_name)
	dashboard.initial_load = false
	# Make sure the widgets are loaded last!
	var sorted_keys : Array = data.keys()
	
	if sorted_keys.has("widgets"):
		sorted_keys.erase("widgets")
		sorted_keys.append("widgets")
	
	for key in sorted_keys:
		if key in ["cloud", "account", "region"] and data[key] == "":
			dashboard.set(key, "All")
		else:
			dashboard.set(key, data[key])
	dashboard.initial_load = true
	dashboard.last_saved_name = dashboard.name
	dashboard.manager = self
	
	if save_dashboard:
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		save_dashboard(dashboard)


func get_user_dashboards() -> Dictionary:
	var dashboard_status := {
		"active_dashboard" : "",
		"open_dashboards" : []
	}
	
	if OS.has_feature("HTML5"):
		var data = HtmlFiles.load_from_local_storage("dashboard_status")
		if data != null:
			var json_parse_result = JSON.parse(data).result
			if typeof(json_parse_result) == TYPE_DICTIONARY:
				dashboard_status = json_parse_result
			else:
				_g.emit_signal("add_toast", "Error while reading local dashboards status", 1)
	else:
		var file := File.new()
		if not file.open("user://dashboard_status", File.READ):
			var json_parse:JSONParseResult = JSON.parse(file.get_as_text())
			dashboard_status = json_parse.result
			file.close()
	return dashboard_status


func save_opened_dashboards():
	var dashboard_status := {
		"active_dashboard" : get_current_tab_control().name.replace(" ","_"),
		"open_dashboards" : []
	}
	
	for dashboard in get_children():
		if dashboard is DashboardContainer or dashboard is DashboardContainerPlaceholder:
			dashboard_status.open_dashboards.append(dashboard.name.replace(" ","_"))
			
	if OS.has_feature("HTML5"):
		HtmlFiles.save_on_local_storage("dashboard_status", JSON.print(dashboard_status))
	else:
		var file := File.new()
		file.open("user://dashboard_status", File.WRITE)
		file.store_string(JSON.print(dashboard_status))
		file.close()


func _on_OpenDashboard_pressed():
	for item in dashboards_list.get_selected_items():
		load_dashboard(dashboards_list.get_item_metadata(item))
	save_opened_dashboards()


func _on_AddDashboard_pressed():
	add_dashboard()
	Analytics.event(Analytics.EventsDashboard.NEW)


func _on_files_dropped(files, _screen):
	var file = File.new()
	if not file.open(files[0], File.READ):
		var data = parse_json(file.get_as_text())
		var json_result : JSONParseResult = JSON.parse(file.get_as_text())
		if not json_result.error:
			import_dashboard_from_data(data)


func _on_DashboardItemList_item_activated(_index):
	_on_OpenDashboard_pressed()


func _on_DashBoardManager_visibility_changed():
	if visible:
		request_saved_dashboards()
		yield(self, "all_dashboards_loaded")
	else:
		save_opened_dashboards()


func _refresh_dashboard_list():
	dashboards_list.clear()
	var idx:= 0
	var available_dashboard_keys : Array = available_dashboards.keys()
	available_dashboard_keys.sort()
	for key in available_dashboard_keys:
		dashboards_list.add_item(available_dashboards[key].dashboard_name)
		dashboards_list.set_item_metadata(idx, key)
		idx += 1


func _on_DashboardItemList_item_selected(_index):
	open_dashboard_btn.show()
	del_dashboard_btn.show()
	dupe_dashboard_btn.show()


func _on_DashboardItemList_nothing_selected():
	dashboards_list.unselect_all()
	open_dashboard_btn.hide()
	del_dashboard_btn.hide()
	dupe_dashboard_btn.hide()


func _on_DashBoardManager_tab_changed(_tab:int=current_tab):
	var new_tab_control:Node = get_tab_control(_tab)
	if new_tab_control.get_class() != "DashboardContainer" and new_tab_control != manager_tab:
		var dashboard_name = new_tab_control.name
		new_tab_control.name = "loading"
		load_dashboard(dashboard_name.replace(" ", "_"))
		new_tab_control.queue_free()
	save_opened_dashboards()


func _on_DashBoardManager_tab_selected(tab):
	if not inform_dashboard_selected:
		return
	emit_signal("dashboard_opened", get_child(tab).name.replace(" ","_"))


func _on_DuplicateDashboard_pressed():
	var selected_idx = dashboards_list.get_selected_items()[0]
	var dashboard_name = dashboards_list.get_item_text(selected_idx)
	rename_new_name = ""
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Name duplicated dashboard",
		"Enter a name for the duplicated dashboard:\n`%s`" % dashboard_name,
		dashboard_name + " " + str(OS.get_unix_time()),
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_rename_confirm_response", [], CONNECT_ONESHOT)


var rename_new_name : String= ""
func _on_rename_confirm_response(_button_clicked:String, _value:String):
	var selected_idx = dashboards_list.get_selected_items()[0]
	var dashboard_name = dashboards_list.get_item_text(selected_idx)
	if _button_clicked == "left":
		if dashboard_name == _value:
			# No name change happened
			return
		# Check if a config with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		request_saved_dashboards()
		yield(self, "all_dashboards_loaded")
		if available_dashboards.has(_value.replace(" ", "_")):
			_g.emit_signal("add_toast", "Duplicate failed", "A dashboard with that name already exists.", 1, self)
			return
		
		rename_new_name = _value
		var dashboard_data :Dictionary = available_dashboards[dashboards_list.get_item_metadata(selected_idx)].duplicate(true)
		dashboard_data.dashboard_name = rename_new_name.replace("_", " ")
		API.put_config_id(self, get_db_config_name(rename_new_name), JSON.print(dashboard_data))


func _on_put_config_id_done(_error, _response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error saving dashboard.", "", 1, self)
		return
	request_saved_dashboards()
	yield(self, "all_dashboards_loaded")
	_refresh_dashboard_list()


func _on_DeleteDashboard_pressed():
	var selected_idx = dashboards_list.get_selected_items()[0]
	var delete_title = "Delete Dashboard?"
	var delete_message = "Do you want to delete the dashboard \"" + dashboards_list.get_item_text(selected_idx) + "\"?"

	if dashboards_list.get_item_text(selected_idx) == DefaultDashboardName:
		delete_title = "Reset Dashboard?"
		delete_message = "%s can not be deleted. Do you want to reset the dashboard?" % DefaultDashboardName

	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		delete_title,
		delete_message,
		"Yes", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String):
	if _response == "left":
		var selected_idx = dashboards_list.get_selected_items()[0]
		var dashboard_node = get_node_or_null(dashboards_list.get_item_text(selected_idx))
		var parent_pos := -1
		if dashboard_node:
			parent_pos = dashboard_node.get_position_in_parent()
		_on_tab_deleted(parent_pos, dashboards_list.get_item_text(selected_idx), false)
		available_dashboards.erase(dashboards_list.get_item_metadata(selected_idx))
		if dashboard_node:
			dashboard_node.queue_free()
		dashboards_list.remove_item(selected_idx)
		yield(get_tree(), "idle_frame")
		save_opened_dashboards()
		Analytics.event(Analytics.EventsDashboard.DELETE)
