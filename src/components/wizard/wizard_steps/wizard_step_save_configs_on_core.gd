extends WizardStep

func start(_data):
	save_configs()


func _on_WizardStep_SaveConfigsOnCore_config_save_fail():
	emit_signal("next", 1)


func _on_WizardStep_SaveConfigsOnCore_config_save_success():
	emit_signal("next", 0)
