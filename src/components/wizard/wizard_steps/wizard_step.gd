extends Control
class_name WizardStep

export var skip_for_history:bool = false
export var intercept_next:bool = false

signal config_save_fail
signal config_save_success

signal update_section_title
signal can_continue
signal can_previous
signal next

var wizard : Node = null
var step_data : Dictionary = {}
var do_intercept_next := false
var section_name := ""
var step_id := ""
var last_step := ""

func start(_data:Dictionary):
	pass


func consume_next():
	pass


var config_action:String = "merge"
var config_key:String = ""
var config_value_path:String = ""
var config_update_body:String = ""


func update_config_string_separator(_value:String, _separator:String):
	var new_value
	if _separator != "":
		var string_array:Array = _value.split(_separator)
		var cleaned_array:= []
		if string_array.empty():
			cleaned_array.append(_value)
		else:
			for sa in string_array:
				sa = sa.strip_edges()
				if sa != "":
					cleaned_array.append(sa)
		new_value = cleaned_array
	else:
		if _value.begins_with("[") or _value.begins_with("{"):
			new_value = str2var(_value)
		else:
			new_value = _value
	update_config(new_value)


func update_config(new_value):
	wizard.config_changed = true
	wizard.emit_signal("setup_wizard_changed_config")
	var path_keys = config_value_path.split(".")
	var current = wizard.remote_configs[config_key]
	var value_key = path_keys[-1]
	
	for i in path_keys.size()-1:
		if current.has(path_keys[i]):
			if typeof(current[path_keys[i]]) == TYPE_DICTIONARY:
				current = current[path_keys[i]]
			elif typeof(current[path_keys[i]]) == TYPE_ARRAY:
				print("ERROR: current[path_keys[i]]) == TYPE_ARRAY")
				# can this even happen?
				pass
			
		else:
			print("key not found, generated.")
			current[path_keys[i]] = {}
			current = current[path_keys[i]]
	
	# If the original config already has the key for the variable
	if current.has(value_key) and not config_action == "set":
		match typeof(current[value_key]):
			TYPE_ARRAY:
				# Handle adding a Dictionary to the Array.
				# This is some extra work as it needs to be compared via hashes.
				if typeof(new_value) == TYPE_DICTIONARY:
					if config_action == "merge":
						var new_hash:int = new_value.hash()
						var found_value:= false
						for elem in current[value_key]:
							if new_hash == elem.hash():
								elem.merge(new_value)
								found_value = true
								break
						if not found_value:
							current[value_key] = new_value
						
					elif config_action == "append":
						current[value_key].append(new_value)
				
				else:
					if config_action == "set":
						current[value_key] = new_value
					
					elif config_action == "append":
						if typeof(new_value) == TYPE_ARRAY:
							current[value_key].append_array(new_value)
						else:
							current[value_key].append(new_value)
					
					elif config_action == "merge":
						if typeof(new_value) == TYPE_ARRAY:
							for elem in new_value:
								if not current[value_key].has(elem):
									current[value_key].append(elem)
						else:
							if not current[value_key].has(value_key):
								current[value_key].append(value_key)
				
			_:
				if typeof(new_value) == TYPE_DICTIONARY:
					current[value_key].merge(new_value)
				else:
					current[value_key] = new_value
	
	# If the original does not have the key
	else:
		current[value_key] = new_value


func save_configs():
	wizard.emit_signal("setup_wizard_collecting")
	for config_id in wizard.remote_configs.keys():
		if _g.ui_test_mode:
			print(Utils.readable_dict(wizard.remote_configs[config_id]))
			API.put_config_id_dry_run(self, config_id, JSON.print(wizard.remote_configs[config_id]))
		else:
			API.put_config_id(self, config_id, JSON.print(wizard.remote_configs[config_id]))


func _on_put_config_id_done(_error:int, _r:ResotoAPI.Response):
	if str(_r.response_code).begins_with("2"):
		_g.emit_signal("add_toast", "Configurations saved", "", OK)
		emit_signal("config_save_success")
	else:
		emit_signal("config_save_fail")


func _on_put_config_id_dry_run_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		emit_signal("config_save_fail")
		_g.emit_signal("add_toast", "Configurations ERROR!", "", FAILED)
		return
	if str(_r.response_code).begins_with("2"):
		_g.emit_signal("add_toast", "Configurations ok!", "", OK)
		emit_signal("config_save_success")
	else:
		_g.emit_signal("add_toast", "Configurations not ok!", "", FAILED)
		emit_signal("config_save_fail")
		print(_r.transformed.result)


func _on_TextLabel_meta_hover_started(_meta:String):
	if _meta.begins_with("http"):
		_g.emit_signal("tooltip_link", "External Link", _meta)
	else:
		_g.emit_signal("tooltip", _meta.trim_prefix("ui_help://"))


func _on_TextLabel_meta_hover_ended(_meta:String):
	_g.emit_signal("tooltip_hide")


func _on_TextLabel_meta_clicked(_meta:String):
	if _meta.begins_with("http"):
		OS.shell_open(_meta)
