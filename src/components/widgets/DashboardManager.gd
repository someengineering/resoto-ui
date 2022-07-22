extends TabContainer

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")


func _on_DashBoardManager_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if not event.is_pressed():
				if get_tab_title(current_tab) == "+":
					var new_tab = dashboard_container_scene.instance()
					new_tab.connect("deleted", self, "_on_tab_deleted")
					add_child(new_tab,true)
					move_child(new_tab, get_tab_control(current_tab).get_position_in_parent())


func _on_tab_deleted(tab) -> void:
	if tab > 0:
		current_tab = tab-1
