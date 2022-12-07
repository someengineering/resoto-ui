extends WizardStep

func start(_data):
	var element_count := 0
	var current : Dictionary
	var value_key : String
	
	if not wizard.remote_configs.has(_data.config):
		if _data.kind == "compare_values":
			conditional_false()
			return
	else:
		var path_keys = _data.variable_name.split(".")
		current = wizard.remote_configs[_data.config]
		value_key = path_keys[-1]
		var found_element := true
		
		for i in path_keys.size()-1:
			if current.has(path_keys[i]):
				if typeof(current[path_keys[i]]) == TYPE_DICTIONARY:
					current = current[path_keys[i]]
				elif typeof(current[path_keys[i]]) == TYPE_ARRAY:
					found_element = false
					if _data.kind == "compare_values":
						conditional_false()
						return
			else:
				found_element = false
				if _data.kind == "compare_values":	
					conditional_false()
					return
		
		if not current.has(value_key):
			found_element = false
			if _data.kind == "compare_values":
				conditional_false()
				return
	
		if found_element:
			var check_for = current[value_key]
			if typeof(check_for) == TYPE_ARRAY or typeof(check_for) == TYPE_DICTIONARY:
				if _data.kind == "element_count":
					element_count = check_for.size()
				elif _data.kind == "compare_values" and _data.operation == "has()":
					result(check_for.has(_data.variable_value))
	
	if _data.kind == "element_count":
		match _data.operation:
			"==":
				result(element_count == int(_data.variable_value))
			"!=":
				result(element_count != int(_data.variable_value))
			">":
				result(element_count > int(_data.variable_value))
			">=":
				result(element_count >= int(_data.variable_value))
			"<":
				result(element_count < int(_data.variable_value))
			"<=":
				result(element_count <= int(_data.variable_value))
	else:
		var check_for = str(current[value_key]).to_lower()
		var compare = str(_data.variable_value).to_lower()
		match _data.operation:
			"":
				conditional_false()
			"==":
				result(compare == check_for)
			"!=":
				result(compare != check_for)
			">":
				result(check_for > compare)
			">=":
				result(check_for >= compare)
			"<":
				result(check_for < compare)
			"<=":
				result(check_for <= compare)


func result(_value:bool):
	if _value:
		conditional_true()
	else:
		conditional_false()


func conditional_true():
	emit_signal("next", 0)


func conditional_false():
	emit_signal("next", 1)
