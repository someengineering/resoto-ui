extends WizardStep

func start(_data:Dictionary):
	if "files_in_home_dir" in wizard.remote_configs["resoto.worker"]["resotoworker"]:
		var files_in_home_dir = wizard.remote_configs["resoto.worker"]["resotoworker"]["files_in_home_dir"]
		
		var service_accounts = wizard.remote_configs["resoto.worker"]["gcp"]["service_account"]
		
		if service_accounts is Array:
			for account in service_accounts:
				files_in_home_dir.erase(account)
				
		wizard.remote_configs["resoto.worker"]["resotoworker"]["files_in_home_dir"] = files_in_home_dir
		wizard.emit_signal("setup_wizard_changed_config")
	emit_signal("next")
