extends Control


func _on_FullTextSearch_text_changed(new_text):
	_g.emit_signal("top_search_update", new_text)


func _on_ResotoHome_visibility_changed():
	_g.emit_signal("resoto_home_visible", is_visible_in_tree())


func _on_ButtonDashboards_pressed():
	_g.emit_signal("nav_change_section", "dashboards")


func _on_ButtonExplore_pressed():
	_g.emit_signal("nav_change_section_explore", "last")


func _on_ButtonConfig_pressed():
	_g.emit_signal("nav_change_section", "config")


func _on_ButtonTerminals_pressed():
	_g.emit_signal("nav_change_section", "terminals")
