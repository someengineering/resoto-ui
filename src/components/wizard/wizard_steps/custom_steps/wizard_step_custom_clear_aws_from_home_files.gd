extends WizardStep

func start(_data:Dictionary):
	if "files_in_home_dir" in wizard.remote_configs["resoto.worker"]["resotoworker"]:
		var files_in_home_dir : Dictionary = wizard.remote_configs["resoto.worker"]["resotoworker"]["files_in_home_dir"]
		if files_in_home_dir != null:
			files_in_home_dir.erase("~/.aws/credentials")
			wizard.remote_configs["resoto.worker"]["resotoworker"]["files_in_home_dir"] = files_in_home_dir
			wizard.emit_signal("setup_wizard_changed_config")
	emit_signal("next")
