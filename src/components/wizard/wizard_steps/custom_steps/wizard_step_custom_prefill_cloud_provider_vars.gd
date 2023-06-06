extends WizardStep

func start(_data:Dictionary):
	if (wizard.remote_configs.has("resoto.worker") and
	wizard.remote_configs["resoto.worker"].has("resotoworker") and
	wizard.remote_configs["resoto.worker"]["resotoworker"].has("collector")):
		var collectors : Array = wizard.remote_configs["resoto.worker"]["resotoworker"]["collector"]
		if collectors.has("k8s"):
			wizard.step_variables["k8s_done"] = "true"
		if collectors.has("aws"):
			wizard.step_variables["aws_done"] = "true"
		if collectors.has("digitalocean"):
			wizard.step_variables["do_done"] = "true"
		if collectors.has("gcp"):
			wizard.step_variables["gcp_done"] = "true"
			
	wizard.step_variables["all_count"] = 0
	API.cli_execute_json("search all | count", self)
	
func _on_cli_execute_json_done(_error: int, _response: ResotoAPI.Response):
	if _error == OK:
		var matches: String = _response.transformed.result[0]
		matches = matches.replace("total matched: ", "")
		wizard.step_variables["all_count"] = str2var(matches)
		
	emit_signal("next")
