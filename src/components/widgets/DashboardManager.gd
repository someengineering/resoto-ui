extends TabContainer

var dashboard_container_scene := preload("res://components/widgets/DashboardContainer.tscn")

func _on_DashBoardManager_tab_selected(tab : int) -> void:
	if get_tab_title(tab) == "+":
		var new_tab = dashboard_container_scene.instance()
		add_child(new_tab,true)
		move_child(new_tab, get_tab_control(tab).get_position_in_parent())
