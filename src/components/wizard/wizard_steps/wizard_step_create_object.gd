extends WizardStep

func start(_data):
	if not wizard.new_json_objects.has(_data.variable_name):
		wizard.new_json_objects[_data.variable_name] = {}
	
	emit_signal("next")
