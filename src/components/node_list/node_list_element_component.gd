extends ComponentContainer


func apply_navigation_arguments():
	if "args" in navigation_arguments and "function" in navigation_arguments:
		var arguments : PoolStringArray = navigation_arguments["args"].percent_decode().split("|")
		
		var var_arguments : Array = []
		
		for argument in arguments:
			var_arguments.append(str2var(argument))
		
		component.callv(navigation_arguments["function"], var_arguments)


func _on_NodeListElement_show(function : String, arguments : Array):
	var data := {
		"function" : function
	}
	var pool := PoolStringArray()
	for argument in arguments:
		pool.append(var2str(argument).percent_encode())
		
	data["args"] = pool.join("|")

	update_navigation_arguments(data)
