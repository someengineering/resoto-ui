extends ComponentContainer


func apply_navigation_arguments():
	if "config_id" in navigation_arguments:
		var combo = component.config_combo as ComboBox
		combo.text = navigation_arguments["config_id"]
	


func _on_ConfigManager_config_changed(config_id):
	if config_id == "":
		return
	update_navigation_arguments({"config_id": config_id})
