extends Node

const SETTINGS_FILE_NAME:String = "user://settings.bin"
const ENC: String = "resotosomeengineering"

signal settings_loaded

var disabled: bool = false

func _enter_tree() -> void:
	# Check for filesystem persistence (Cookies in browser, local user dir on desktop)
	disabled = !OS.is_userfs_persistent()


func check_for_settings() ->bool:
	if disabled:
		return false
	var settings = File.new()
	var settings_path = SETTINGS_FILE_NAME
	
	if not settings.file_exists( settings_path ):
		return false
	else:
		return true


func load_settings() -> void:
	if disabled:
		return
	var settings = load_settings_file()
	API.psk = settings[0].psk
	_g.ui_shrink = settings[0].ui_shrink
	emit_signal("settings_loaded", settings[1])


func load_settings_file() -> Array:
	if disabled:
		return [clear_settings(), false]
	var settings = File.new()
	var settings_path = SETTINGS_FILE_NAME
	
	if not settings.file_exists(settings_path):
		return [clear_settings(), false]
	
	settings.open_encrypted_with_pass(settings_path, File.READ, ENC)
	var settings_data = clear_settings()
	while(settings.get_position() < settings.get_len()):
		var settings_var = settings.get_var()
		for key in settings_data.keys():
			if settings_var.has(key):
				settings_data[key] = settings_var[key]
	settings.close()
	return [settings_data, true]


func save_settings() -> void:
	if disabled:
		return
	var settings_path = SETTINGS_FILE_NAME
	var settings_data = clear_settings()
	
	settings_data.psk = API.psk
	settings_data.ui_shrink = _g.ui_shrink
	
	var settings = File.new()
	settings.open_encrypted_with_pass(settings_path, File.WRITE, ENC)
	settings.store_var(settings_data)
	settings.close()


func clear_settings() -> Dictionary:
	var game_save_struct:Dictionary = {
		"psk" : "changeme",
		"ui_shrink" : 1.0,
	}
	return game_save_struct


func delete_settings() -> void:
	var settings_path = SETTINGS_FILE_NAME
	var settings = File.new()
	if not settings.file_exists(settings_path):
		return
	var dir = Directory.new()
	dir.remove(settings_path)
