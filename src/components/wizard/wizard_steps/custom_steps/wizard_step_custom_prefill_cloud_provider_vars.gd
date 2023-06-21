extends WizardStep

var workflow_done := false
var search_all_done := false

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
	wizard.step_variables["running_workflows"] = 0
	API.cli_execute_json("search all | count", self)
	API.cli_execute_json("workflow running", self, "_on_cli_execute_json_workflow_data", "_on_cli_execute_json_workflow_done")
	
func _on_cli_execute_json_workflow_data(_error:int, _response: ResotoAPI.Response):
	pass
	
	
func _on_cli_execute_json_workflow_done(_error:int, _response: ResotoAPI.Response):
	if _error:
		return
		
	wizard.step_variables["running_workflows"] = _response.transformed.result.size()
	workflow_done = true
	if search_all_done:
		emit_signal("next")
	
func _on_cli_execute_json_done(_error: int, _response: ResotoAPI.Response):
	if _error == OK:
		var matches: String = _response.transformed.result[0]
		matches = matches.replace("total matched: ", "")
		wizard.step_variables["all_count"] = str2var(matches)
	
	search_all_done = true
	if workflow_done:
		emit_signal("next")
	
