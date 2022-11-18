extends WizardStep

func start(_data:Dictionary):
	emit_signal("can_previous", false)
	API.cli_execute("workflow run collect_and_cleanup", self)
	$VBoxContainer/CenterContainer/Loading.start()


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		return


func _on_CollectRunDisplay_all_done():
	$VBoxContainer/CenterContainer/Loading.stop()
	emit_signal("can_continue")
