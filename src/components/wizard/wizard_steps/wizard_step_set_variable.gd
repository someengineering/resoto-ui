extends WizardStep

func start(_data):
	wizard.step_variables[_data.variable_name] = _data.variable_value
	emit_signal("next")
