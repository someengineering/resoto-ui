extends Node

const SETTINGS_FILE_NAME:String = "user://settings.bin"
const ENC: String = "resotosomeengineering"

signal settings_loaded

var disabled: bool = false
var node_data_last_save:= {}

func _enter_tree() -> void:
	# Check for filesystem persistence (Cookies in browser, local user dir on desktop)
	disabled = !OS.is_userfs_persistent()


func check_for_settings() ->bool:
	if disabled:
		return false
	var settings : File = File.new()
	var settings_path : String = SETTINGS_FILE_NAME
	
	if not settings.file_exists( settings_path ):
		return false
	else:
		return true


func load_settings() -> void:
	if disabled:
		return
	var settings : Array = load_settings_file()
	API.psk = settings[0].psk
	_g.ui_scale = settings[0].ui_scale
	_g.terminal_scrollback = settings[0].terminal_scrollback
	if settings[0].has("persistent_nodes"):
		restore_node_data(settings[0].persistent_nodes)
	emit_signal("settings_loaded", settings[1])


func load_settings_file() -> Array:
	if disabled:
		return [clear_settings(), false]
	var settings :File = File.new()
	var settings_path : String = SETTINGS_FILE_NAME
	
	if not settings.file_exists(settings_path):
		return [clear_settings(), false]
	
	settings.open_encrypted_with_pass(settings_path, File.READ, ENC)
	var settings_data : Dictionary = clear_settings()
	while(settings.get_position() < settings.get_len()):
		var settings_var = settings.get_var()
		for key in settings_data.keys():
			if settings_var.has(key):
				settings_data[key] = settings_var[key]
	settings.close()
	return [settings_data, true]


func restore_node_data(_node_data:Dictionary):
	node_data_last_save = _node_data
	for n in get_tree().get_nodes_in_group("persistent"):
		if (not n.has_method("set_persistent_data")
		or not _node_data.keys().has(n.persistent_key)):
			continue
		n.set_persistent_data(_node_data[n.persistent_key])


func save_settings() -> void:
	if disabled:
		return
	var settings_path : String = SETTINGS_FILE_NAME
	var settings_data : Dictionary = clear_settings()
	
	settings_data.psk = API.psk
	settings_data.ui_scale = _g.ui_scale
	settings_data.terminal_scrollback = _g.terminal_scrollback
	
	var collected_data:= {}
	for n in get_tree().get_nodes_in_group("persistent"):
		if not n.has_method("get_persistent_data"):
			continue
		var node_data : Dictionary = n.get_persistent_data()
		collected_data[node_data.key] = node_data.data
	settings_data.persistent_nodes = collected_data
	
	var settings : File = File.new()
	settings.open_encrypted_with_pass(settings_path, File.WRITE, ENC)
	settings.store_var(settings_data)
	settings.close()


func clear_settings() -> Dictionary:
	var game_save_struct:Dictionary = {
		"psk" : "changeme",
		"ui_scale" : 1.0,
		"terminal_scrollback" : [],
		"persistent_nodes" : {}
	}
	return game_save_struct


func delete_settings() -> void:
	var settings_path : String = SETTINGS_FILE_NAME
	var settings : File = File.new()
	if not settings.file_exists(settings_path):
		return
	var dir : Directory = Directory.new()
	dir.remove(settings_path)
