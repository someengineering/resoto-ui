extends MarginContainer

signal leave_request_handled

var can_leave_section := true setget set_can_leave_section
var is_collecting := false

func _ready():
	_g.connect("setup_wizard_start", self, "_start_wizard")
	$WizardControl.connect("setup_wizard_collecting", self, "_on_is_collecting")
	$WizardControl.connect("setup_wizard_changed_config", self, "set_can_leave_section", [false])
	_g.connect("connected_to_resotocore", self, "_check_for_setup_wizard_autostart", [], CONNECT_ONESHOT)
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
	_g.emit_signal("nav_change_section", "home")
	if not can_leave_section:
		yield(self, "leave_request_handled")
		if can_leave_section:
			_on_WizardControl_setup_wizard_finished()
		return
	_g.emit_signal("setup_wizard_done")
	is_collecting = false
	Analytics.event(Analytics.EventWizard.FINISH)
	$WizardControl.current_step = null


func _check_for_setup_wizard_autostart():
	API.get_configs(self)
	
func _on_get_configs_done(_error: int, _response: ResotoAPI.Response) -> void:
	if _error:
		return
		
	if "resoto.ui.setup" in _response.transformed.result:
		API.get_config_id(self, "resoto.ui.setup")
	else:
		API.get_config_id(self, "resoto.worker")


# Check for automatic start of the Setup Wizard
func _on_get_config_id_done(_error:int, _response:ResotoAPI.Response, _config_key:String) -> void:
	if _error:
		return

	elif _config_key == "resoto.ui.setup":
		var setup_config: Dictionary = _response.transformed.result
		if "resotosetup" in setup_config and "completed" in setup_config.resotosetup:
			if str2var(setup_config.resotosetup.completed):
				return
	_start_wizard()
