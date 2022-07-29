extends TabContainer

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")


func _on_DashBoardManager_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if not event.is_pressed():
				if get_tab_title(current_tab) == "+":
					add_dashboard()
		if event.button_index == BUTTON_RIGHT and event.is_pressed():
			load_data()
		if event.button_index == BUTTON_MIDDLE and event.is_pressed():
			save_data()

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


func save_data():
	var data : Array = []
	for dashboard in get_children():
		if dashboard.has_method("get_data"):
			data.append(dashboard.get_data())
			
	var file := File.new()
	file.open("/home/pablo/test-dashboard", File.WRITE)
	file.store_string(JSON.print(data, "\t"))
	file.close()
	
func load_data():
	for dashboard in get_children():
		if dashboard.has_method("get_data"):
			remove_child(dashboard)
			dashboard.queue_free()
			
	var file : File = File.new()
	file.open("/home/pablo/test-dashboard", File.READ)
	var data : Array = JSON.parse(file.get_as_text()).result
	for dashboard in data:
		add_dashboard(dashboard.dashboard_name)
		yield(get_tree(),"idle_frame")
		var d = get_node(dashboard.dashboard_name)
		for key in dashboard:
			d.set(key, dashboard[key])
			

		
	
	
