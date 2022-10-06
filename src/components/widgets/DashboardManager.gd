extends TabContainer

signal all_dashboards_loaded

const number_keys : Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")
var available_dashboards : Dictionary = {}
var total_saved_dashboards : int = 0
var dashboards_loaded : int = 0

onready var dashboards_list = find_node("DashboardItemList")


func _ready():
	set_tab_title(0, "Manage Dashboards")
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
	var new_tab = dashboard_container_scene.instance()
	if dashboard_name != "":
		new_tab.dashboard_name = dashboard_name

	new_tab.connect("deleted", self, "_on_tab_deleted")
	add_child(new_tab,true)
	move_child(new_tab, get_tab_control(current_tab).get_position_in_parent())
	
	new_tab.connect("dashboard_changed", self, "save_dashboard")
	new_tab.connect("dashboard_closed", self, "close_dashboard")
	
	yield(VisualServer,"frame_post_draw")
	
	new_tab.dashboard._on_Grid_resized()


func _on_tab_deleted(tab) -> void:
	if tab > 0:
		current_tab = tab-1
	if get_child_count() <= 2:
		request_saved_dashboards()


func save_dashboard(dashboard : DashboardContainer):
	var data = dashboard.get_data()
	API.cli_execute("configs delete resoto.ui.dashboard."+dashboard.last_saved_name.replace(" ", "_"), self)
	API.patch_config_id(self, "resoto.ui.dashboard."+dashboard.name.replace(" ","_"), JSON.print(data))
	dashboard.last_saved_name = dashboard.dashboard_name


func close_dashboard(dashboard : DashboardContainer):
	dashboard.queue_free()


func _on_cli_execute_done(_error : int, _response):
	pass


func _on_patch_config_id_done(_error : int, _response):
	_g.emit_signal("add_toast", "Your Dashboard has been saved!", "")


func request_saved_dashboards() -> void:
	API.get_configs(self)
	

func _on_get_configs_done(_error: int, response):
	available_dashboards.clear()
	total_saved_dashboards = 0
	for config in response.transformed.result:
		config = config as String
		if config.begins_with("resoto.ui.dashboard"):
			API.get_config_id(self, config)
			total_saved_dashboards += 1


func _on_get_config_id_done(_error : int, _response, _config):
	var dashboard = _response.transformed.result
	if dashboard is Dictionary:
		available_dashboards[dashboard.dashboard_name.replace(" ", "_")] = dashboard
		dashboards_loaded += 1
		if total_saved_dashboards <= dashboards_loaded:
			emit_signal("all_dashboards_loaded")


func _on_DashBoardManager_all_dashboards_loaded():
	dashboards_list.clear()
	for dashboard in available_dashboards:
		dashboards_list.add_item(dashboard)


func open_user_dashboards():
	for dashboard_name in get_user_dashboards():
		load_dashboard(dashboard_name)


func load_dashboard(dashboard_name : String):
	if not available_dashboards.has(dashboard_name):
		return
	var data : Dictionary = available_dashboards[dashboard_name]
	create_dashboard_with_data(data)


func create_dashboard_with_data(data):
	if not "dashboard_name" in data:
		return
	var dashboard_name = data["dashboard_name"]
	var dashboard = get_node_or_null(dashboard_name)
	if dashboard != null:
		current_tab = get_children().find(dashboard)
		return
		
	add_dashboard(dashboard_name)
	dashboard = get_node(dashboard_name)
	dashboard.initial_load = false
	for key in data:
		dashboard.set(key, data[key])
	dashboard.initial_load = true
	dashboard.last_saved_name = dashboard.name


func get_user_dashboards() -> PoolStringArray:
	var dashboards_names : PoolStringArray = []
	if OS.has_feature("HTML5"):
		dashboards_names = HtmlFiles.load_from_local_storage("dashboards")
	else:
		var file := File.new()
		if not file.open("user://dashboards", File.READ):
			dashboards_names = JSON.parse(file.get_as_text()).result
			file.close()
	return dashboards_names


func _notification(what):
	if what == NOTIFICATION_WM_FOCUS_OUT:
		get_tree().paused = true
		var dashboards_names : Array = []
		for dashboard in get_children():
			if dashboard is DashboardContainer:
				dashboards_names.append(dashboard.name.replace(" ","_"))
				
		if OS.has_feature("HTML5"):
			HtmlFiles.save_on_local_storage("dashboards", JSON.print(dashboards_names))
		else:
			var file := File.new()
			file.open("user://dashboards", File.WRITE)
			file.store_string(JSON.print(dashboards_names))
			file.close()
	elif what == NOTIFICATION_WM_FOCUS_IN:
		get_tree().paused = false


func _on_OpenDashboard_pressed():
	for item in dashboards_list.get_selected_items():
		load_dashboard(dashboards_list.get_item_text(item))


func _on_AddDashboard_pressed():
	add_dashboard()


func _on_files_dropped(files, _screen):
	var file = File.new()
	if not file.open(files[0], File.READ):
		var data = parse_json(file.get_as_text())
		create_dashboard_with_data(data)


func _on_DashboardItemList_item_activated(_index):
	_on_OpenDashboard_pressed()


func _on_DashBoardManager_visibility_changed():
	if visible:
		request_saved_dashboards()
		yield(self, "all_dashboards_loaded")
		open_user_dashboards()
