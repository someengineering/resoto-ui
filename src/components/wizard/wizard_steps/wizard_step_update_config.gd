extends WizardStep

func start(_data):
	config_key			= _data.config_key
	config_action		= _data.action
	config_value_path	= _data.value_path
	
	var value		= _data.value
	var separator	= _data.separator if _data.has("separator") else ""
	
	update_config_string_separator(value, separator)
	emit_signal("next")
