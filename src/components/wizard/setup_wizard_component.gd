extends MarginContainer


func _ready():
	_g.connect("setup_wizard_start", self, "_start_wizard")
	_g.connect("connected_to_resotocore", self, "_check_for_setup_wizard_autostart")
	connect("visibility_changed", self, "_on_SetupWizardComponent_visibility_changed")


func _start_wizard():
	Analytics.event(Analytics.EventWizard.START)
	_g.emit_signal("nav_change_section", "setup_wizard")


func _on_SetupWizardComponent_visibility_changed():
	if visible and $WizardControl.current_step == null:
		$WizardControl.load_wizard_graph("setup_wizard")


func _on_WizardControl_setup_wizard_finished():
	Analytics.event(Analytics.EventWizard.FINISH)
	_g.emit_signal("nav_change_section", "home")


func _check_for_setup_wizard_autostart():
	API.get_config_id(self, "resoto.worker")


# Check for automatic start of the Setup Wizard
func _on_get_config_id_done(_error:int, _response:ResotoAPI.Response, _config_key:String) -> void:
	if _error:
		return
	var worker_config : Dictionary = _response.transformed.result
	if worker_config.has("resotoworker") and worker_config.resotoworker.has("collector"):
		# If the collector array has more than one element
		# (two when example was found), do not start the setup wizard
		var min_collectors := 2 if worker_config.resotoworker.collector.has("example") else 1
		if worker_config.resotoworker.collector.size() >= min_collectors:
			return
	_start_wizard()
