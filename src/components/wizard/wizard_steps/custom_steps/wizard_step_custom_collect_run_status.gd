extends WizardStep

func start(_data:Dictionary):
	emit_signal("can_previous", false)
	$VBoxContainer/CollectRunDisplay.wait_for_config_update()
	$WaitForConfigUpdateTimer.start()


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
	API.cli_execute("workflow run collect_and_cleanup", self)
