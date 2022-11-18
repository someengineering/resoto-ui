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
	emit_signal("next")
