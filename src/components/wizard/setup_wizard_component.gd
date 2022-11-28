extends MarginContainer

signal leave_request_handled

var can_leave_section := true setget set_can_leave_section
var is_collecting := false

func _ready():
	_g.connect("setup_wizard_start", self, "_start_wizard")
	$WizardControl.connect("setup_wizard_collecting", self, "_on_is_collecting")
	$WizardControl.connect("setup_wizard_changed_config", self, "set_can_leave_section", [false])
	_g.connect("connected_to_resotocore", self, "_check_for_setup_wizard_autostart")
	connect("visibility_changed", self, "_on_SetupWizardComponent_visibility_changed")


func leave_section():
	if is_collecting:
		_g.emit_signal("setup_wizard_minimized", true)


func leave_section_request():
	# Check if the user in in the middle of the setup wizard
	var confirm_popup = _g.popup_manager.show_confirm_popup(
	"Close Setup Wizard?",
	"Do you want to close the Setup Wizard before finishing the Resoto Setup?\n\nChanges will not be saved until finishing the Setup Wizard.",
	"Yes", "No")
	confirm_popup.connect("response", self, "_on_leave_request_response", [], CONNECT_ONESHOT)


func _on_leave_request_response(_response:String):
	if _response == "left":
		can_leave_section = true
		emit_signal("leave_request_handled")
	else:
		emit_signal("leave_request_handled")


func _on_is_collecting():
	can_leave_section = true
	is_collecting = true


func set_can_leave_section(_value:bool):
	can_leave_section = _value


func _start_wizard():
	Analytics.event(Analytics.EventWizard.START)
	_g.emit_signal("nav_change_section", "setup_wizard")


func _on_SetupWizardComponent_visibility_changed():
	if visible and $WizardControl.current_step == null:
		$WizardControl.load_wizard_graph("setup_wizard")


func _on_WizardControl_setup_wizard_finished():
	is_collecting = false
	Analytics.event(Analytics.EventWizard.FINISH)
	_g.emit_signal("nav_change_section", "home")
	$WizardControl.current_step = null


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
