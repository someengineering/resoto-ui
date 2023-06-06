extends WizardStep

func start(_data):
	if not _data.variable_name in wizard.step_variables:
		conditional_false()
		return
		
	var value = wizard.step_variables[_data.variable_name]
	if _data.kind == "element_count":
		if typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			value = value.size()
		else:
			conditional_false()
			return
	
	var expression = Expression.new()
	expression.parse("%s %s %s" % [var2str(value), _data.operation, _data.variable_value])
	result(expression.execute())


func result(_value:bool):
# warning-ignore:standalone_ternary
	conditional_true() if _value else conditional_false()


func conditional_true():
	emit_signal("next", 0)


func conditional_false():
	emit_signal("next", 1)
