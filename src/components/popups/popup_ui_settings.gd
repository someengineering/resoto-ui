extends CustomPopupWindow

signal configs_received
signal config_id_received

var config_keys : Array = []
var config_dicts : Dictionary = {}

var cleanup : bool = false setget set_cleanup
var cleanup_dry_run : bool = false setget set_cleanup_dry_run

var is_dirty : bool = false

onready var show_psk_icon := $"%ShowPSKIcon"
onready var psk_line_edit := $"%PSKLineEdit"
onready var adress_line_edit := $"%AdressEdit"
onready var port_line_edit := $"%PortEdit"
onready var accept_button := $Content/Footer/Footerbar/AddWidgetButton
onready var footerbar := $Content/Footer/Footerbar

func _on_CancelButton_pressed() -> void:
	is_dirty = false
	config_keys.clear()
	config_dicts.clear()
	_close_popup()


func _close_popup() -> void:
	is_dirty = false
	config_keys.clear()
	config_dicts.clear()
	hide()


# Accepting changes.
func _on_AddWidgetButton_pressed() -> void:
	if is_dirty:
		for key in config_dicts:
			API.put_config_id(self, key, JSON.print(config_dicts[key]))
	
	# Get connection settings
	var a_t = adress_line_edit.text.strip_edges()
	var adress = a_t.split("://")
	adress.remove(0)
	adress = adress[0].split(":")
	var use_ssl = a_t.begins_with("https:")
	var port = int(port_line_edit.text)
	var psk : String = psk_line_edit.text
	if (API.adress != adress[0] or API.port != int(port) or API.psk != psk or API.use_ssl != use_ssl):
		API.connection_config(adress[0], int(port), psk, use_ssl)
		_g.popup_manager.open_popup("ConnectPopup")
		_g.emit_signal("connect_to_core")
	SaveLoadSettings.save_settings()
	hide()


func _on_UISettings_about_to_show() -> void:
	if _g.os == "MacOS":
		footerbar.move_child(accept_button, 1)
	else:
		footerbar.move_child(accept_button, 0)
	is_dirty = false
	$Content/Content/SettingsTabs.current_tab = 0
	$"%ScaleLevelLabel".text = str(_g.ui_scale*100) + " %"
	config_keys.clear()
	config_dicts.clear()
	API.get_configs(self)
	set_ui_test_mode(_g.ui_test_mode)
	get_config_value("resoto.worker", ["resotoworker", "cleanup"], "set_cleanup")
	get_config_value("resoto.worker", ["resotoworker", "cleanup_dry_run"], "set_cleanup_dry_run")
	psk_line_edit.text = API.psk
	var protocol:= "https://" if API.use_ssl else "http://"
	adress_line_edit.text = protocol + API.adress
	port_line_edit.text = str(API.port)
	


func set_cleanup_dry_run(_cleanup_dry_run:bool) -> void:
	cleanup_dry_run = _cleanup_dry_run
	$"%CleanupDryRunLabelButton".pressed = cleanup_dry_run
	$"%CleanupDryRunLabelButton"._on_toggle(cleanup_dry_run)


func set_cleanup(_cleanup:bool) -> void:
	cleanup = _cleanup
	$"%CleanupDryRunLabel".visible = cleanup
	$"%CleanupDryRunLabelButton".visible = cleanup
	$"%CleanupDryRunHint".visible = cleanup
	rect_size.y = 1
	$"%CleanupButton".pressed = cleanup
	$"%CleanupButton"._on_toggle(cleanup)


func set_ui_test_mode(_ui_test_mode:bool) -> void:
	_g.ui_test_mode = _ui_test_mode
	$"%UITestModeButton".pressed = _g.ui_test_mode
	$"%UITestModeButton"._on_toggle(_g.ui_test_mode)


func _on_get_configs_done(_error:int, _response:ResotoAPI.Response) -> void:
	if _error or _response.transformed.result.empty():
		return
	config_keys = _response.transformed.result
	emit_signal("configs_received")


func get_config_value(_config_key:String, _config_path:Array, _setter:String) -> void:
	if config_keys.empty():
		yield(self, "configs_received")
	API.get_config_id(self, _config_key)
	yield(self, "config_id_received")
	if config_dicts.has(_config_key):
		var dict_part = config_dicts[_config_key]
		for key in _config_path:
			dict_part = dict_part[key]
		call(_setter, dict_part)


func _on_get_config_id_done(_error:int, _response:ResotoAPI.Response, _config_key:String) -> void:
	if _error:
		if _error == ERR_PRINTER_ON_FIRE:
			return
		return
	config_dicts[_config_key] = _response.transformed.result
	emit_signal("config_id_received", _config_key)


func set_config_value(_config_key:String, _config_path:Array, _new_value) -> void:
	if config_keys.empty():
		API.get_configs(self)
		yield(self, "configs_received")
	API.get_config_id(self, _config_key)
	yield(self, "config_id_received")
	var set_success : bool = Utils.set_path(config_dicts[_config_key], _config_path, _new_value)
	if set_success:
		is_dirty = true


func _on_put_config_id_done(_error:int, _response:ResotoAPI.Response) -> void:
	if _error:
		return
	var config_revision:String = ""
	if "Resoto-Config-Revision" in _response.headers:
		config_revision = "Revision: " + _response.headers["Resoto-Config-Revision"]
	_g.emit_signal("add_toast", "Configuration updated successfully.", config_revision, 0, self)


func _on_CleanupDryRunLabelButton_pressed() -> void:
	cleanup_dry_run = !cleanup_dry_run
	set_config_value("resoto.worker", ["resotoworker", "cleanup_dry_run"], cleanup_dry_run)


func _on_CleanupButton_pressed() -> void:
	cleanup = !cleanup
	$"%CleanupDryRunLabel".visible = cleanup
	$"%CleanupDryRunLabelButton".visible = cleanup
	$"%CleanupDryRunHint".visible = cleanup
	rect_size.y = 1
	set_config_value("resoto.worker", ["resotoworker", "cleanup"], cleanup)


const hide_tex = preload("res://assets/icons/icon_128_show.svg")
const show_tex = preload("res://assets/icons/icon_128_hide.svg")
func _on_ShowPSKIcon_toggled(button_pressed:bool) -> void:
	show_psk_icon.icon_tex = hide_tex if button_pressed else show_tex
	psk_line_edit.secret = !button_pressed


func _on_ButtonUIScaleMinus_pressed() -> void:
	_g.emit_signal("ui_scale_decrease")
	$"%ScaleLevelLabel".text = str(_g.ui_scale*100) + " %"


func _on_ButtonUIScalePlus_pressed() -> void:
	_g.emit_signal("ui_scale_increase")
	$"%ScaleLevelLabel".text = str(_g.ui_scale*100) + " %"


func _on_SettingsTabs_tab_changed(_tab) -> void:
	rect_size = Vector2.ONE


func _on_SetupWizardStartButton_pressed():
	_g.emit_signal("setup_wizard_start")
	_close_popup()


func _on_UITestModeButton_pressed():
	_g.ui_test_mode = !_g.ui_test_mode


func _on_WizardEditorStartButton_pressed():
	get_tree().change_scene("res://components/wizard_editor/wizard_editor_component.tscn")
