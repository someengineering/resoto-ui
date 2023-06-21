extends WizardStep


func start(_data:Dictionary):
	emit_signal("can_previous", false)
	$VBoxContainer/CollectRunDisplay.wait_for_config_update()
	$WaitForConfigUpdateTimer.start()
	
	if wizard.config_changed:
		wizard.step_variables["startup"] = false 
		$VBoxContainer/StartupLabel.hide()
	else:
		wizard.step_variables["startup"] = true 
		$VBoxContainer/StartupLabel.show()


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		return


func _on_CollectRunDisplay_all_done(_e):
	$VBoxContainer/CenterContainer/Loading.stop()
	Analytics.event(Analytics.EventWizard.COLLECT_DONE)
	emit_signal("can_continue")


func _on_CollectRunDisplay_started():
	$VBoxContainer/CenterContainer/Loading.start()


func _on_WaitForConfigUpdateTimer_timeout():
	$VBoxContainer/CollectRunDisplay.wait_for_core()
	yield(get_tree(), "idle_frame")
	if wizard.config_changed:
		API.cli_execute("workflow run collect_and_cleanup", self)
	else:
		if wizard.step_variables["running_workflows"] == 0:
			API.cli_execute_json("search all | count", self, "_on_search_all_done")
		else:
			$CheckRunningWorkflows.start()


func _on_CheckRunningWorkflows_timeout():
		API.cli_execute_json("workflow running", self)
	
func _on_cli_execute_json_data(_error:int, _response: ResotoAPI.Response):
	pass
	
	
func _on_cli_execute_json_done(_error:int, _response: ResotoAPI.Response):
	if not _error:
		wizard.step_variables["running_workflows"] = _response.transformed.result.size()
		if wizard.step_variables["running_workflows"] > 0:
			$CheckRunningWorkflows.start()
		else:
			API.cli_execute_json("search all | count", self,"_on_search_all_data", "_on_search_all_done")

func _on_search_all_data(_e, _r):
	pass

func _on_search_all_done(_error : int, _response : ResotoAPI.Response):
	if _error == OK:
		var matches: String = _response.transformed.result[0]
		matches = matches.replace("total matched: ", "")
		wizard.step_variables["all_count"] = str2var(matches)
	else:
		wizard.step_variables["all_count"] = 0 
	emit_signal("next")
