extends TabContainer

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")

func _on_DashBoardManager_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if not event.is_pressed():
				if get_tab_title(current_tab) == "+":
					add_dashboard()

func add_dashboard(dashboard_name : String = "", uuid : String = ""):
	var new_tab = dashboard_container_scene.instance()
	if dashboard_name != "":
		new_tab.dashboard_name = dashboard_name
	if uuid == "":
		new_tab.uuid = generate_uuid()
	new_tab.connect("deleted", self, "_on_tab_deleted")
	add_child(new_tab,true)
	move_child(new_tab, get_tab_control(current_tab).get_position_in_parent())

func _on_tab_deleted(tab) -> void:
	if tab > 0:
		current_tab = tab-1

func save_dashboard(dashboard : DashboardContainer):
	var data = dashboard.get_data()
	
	if OS.has_feature("HTML5"):
		for dashboard_key in HtmlFiles.get_local_storage_keys():
			if dashboard.uuid in dashboard_key:
				HtmlFiles.delete_from_local_storage(dashboard_key)
				break

		HtmlFiles.save_on_local_storage("resoto.ui.dashboard.%s.%s" % [dashboard.name, dashboard.uuid], JSON.print(data))
	else:
		var file := File.new()
		file.open("user://resoto.ui.dashboard.%s.%s" % [dashboard.name, dashboard.uuid], File.WRITE)
		file.store_string(JSON.print(data, "\t"))
		file.close()
	
	_g.emit_signal("add_toast", "Your Dashboard was saved!", "")

func load_all_dashboards():
	for dashboard in get_children():
		if dashboard.has_method("get_data"):
			remove_child(dashboard)
			dashboard.queue_free()
			
	var dashboards_data = get_saved_dashboards()
	for dashboard_name in dashboards_data:
		var data : Dictionary = dashboards_data[dashboard_name]
		add_dashboard(dashboard_name, data["uuid"])
		var dashboard = get_node(dashboard_name)
		dashboard.initial_load = false
		for key in data:
			dashboard.set(key, data[key])
		dashboard.initial_load = true

func get_saved_dashboards() -> Dictionary:
	var dashboards : Dictionary = {}
	
	if OS.has_feature("HTML5"):
		var names = HtmlFiles.get_local_storage_keys()
		for n in names:
			if n.begins_with("resoto.ui.dashboard"):
				var data = HtmlFiles.load_from_local_storage(n)
				dashboards[data["dashboard_name"]] = data
	else:
		var dir := Directory.new()
		dir.open("user://")
		dir.list_dir_begin()
		while true:
			var file_name : String = dir.get_next()
			if file_name == "":
				break
			if file_name.begins_with("resoto.ui.dashboard"):
				var file = File.new()
				print(file.open("user://"+file_name, File.READ))
				var data : Dictionary = JSON.parse(file.get_as_text()).result
				dashboards[data["dashboard_name"]] = data
	
	return dashboards

func generate_uuid() -> String:
	var uuid : String
	if OS.has_feature("HTML5"):
		uuid =  HtmlFiles.get_uuid()
	else:
		# from here https://www.cryptosys.net/pki/uuid-rfc4122.html
		var data = Crypto.new().generate_random_bytes(16)
		data[6] = (data[6] & 0x0f) | 0x40
		data[8] = (data[8] & 0x3f) | 0x80
		uuid = '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % (data as Array)
	return uuid
