extends WizardStep

func start(_data):
	if not wizard.new_json_objects.has(_data.variable_name):
		wizard.new_json_objects[_data.variable_name] = {}
	config_key = _data.config_key
	config_action = _data.action
	config_value_path = _data.value_path
	var final_value = [wizard.new_json_objects[_data.variable_name]] if _data.wrap_as_array else wizard.new_json_objects[_data.variable_name]
	
	
	update_config(final_value)
	emit_signal("next")
