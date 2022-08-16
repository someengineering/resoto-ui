extends TabContainer

signal all_dashboards_loaded

const number_keys : Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")
var available_dashboards : Dictionary = {}
var total_saved_dashboards : int = 0
var dashboards_loaded : int = 0

func _on_DashBoardManager_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if not event.is_pressed():
				if get_tab_title(current_tab) == "+":
					add_dashboard()

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
	

func _on_tab_deleted(tab) -> void:
	if tab > 0:
		current_tab = tab-1

func save_dashboard(dashboard : DashboardContainer):
	var data = dashboard.get_data()
	API.cli_execute("configs delete resoto.ui.dashboard."+dashboard.last_saved_name.replace(" ", "_"), self)
	API.patch_config_id(self, "resoto.ui.dashboard."+dashboard.name.replace(" ","_"), JSON.print(data))

func _con_cli_execute_done(_error : int, _response):
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
		available_dashboards[dashboard["dashboard_name"].replace(" ", "_")] = dashboard
		dashboards_loaded += 1
		if total_saved_dashboards <= dashboards_loaded:
			emit_signal("all_dashboards_loaded")


func _on_DashBoardManager_all_dashboards_loaded():
	for dashboard_name in get_user_dashboards():
		load_dashboard(dashboard_name)
	

func load_dashboard(dashboard_name : String):
	var data : Dictionary = available_dashboards[dashboard_name]
	add_dashboard(dashboard_name)
	var dashboard = get_node(dashboard_name)
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
	if what == NOTIFICATION_WM_QUIT_REQUEST:
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
