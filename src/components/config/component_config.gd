extends Control

export var descriptions_as_hints:bool = true
const DEFAULT_COLLAPSED_CATEGORIES : Array = ["ui", "dashboard", "report"]
const BASE_KINDS : Array = [
	"string",
	"int32",
	"int64",
	"float",
	"double",
	"any",
	"boolean",
	"date",
	"datetime",
	"duration",
	"trafo.duration_to_datetime",
	]
const ProtectedConfigs : Array= ["resoto.core", "resoto.worker", "resoto.core.commands", "resoto.metrics"]
const DashboardPrefix := "resoto.ui.dashboard."
const DefaultConfig : String = "resoto.core"

signal model_ready
signal close_config
signal config_received
signal pages_built
signal config_updated
signal config_list_refreshed
signal config_changed(config_id)

var config_req: ResotoAPI.Request
var config_put_req: ResotoAPI.Request

var config_model : Dictionary = {}
var config_keys : Array

var active_config_key : String = ""
var active_config : Dictionary
var config_page : Control = null

var use_raw_mode : bool = false

var tabs_content : Dictionary = {}
var tabs_content_keys : Array = []
var _active_tab_id : int = -1

onready var tabs : Tabs = find_node("Tabs")
onready var content = $"%Content"
onready var config_combo = $"%ConfigCombo"


func _input(event:InputEvent):
	if is_visible_in_tree() and event.is_action_pressed("save_shortcut"):
		save_config()


func history_navigate_to_config(_config_key:String):
	if active_config_key == "":
		active_config_key = _config_key
	else:
		config_combo.text = _config_key


func start() -> void:
	if config_model.empty():
		API.get_config_model(self)
	load_configs()


func load_configs() -> void:
	API.get_configs(self)
	yield(self, "config_list_refreshed")
	config_combo.set_text(active_config_key)
	_g.emit_signal("add_toast", "Configs received from Resoto Core", "", 0, self)


func _on_get_config_model_done(_error:int, _response:ResotoAPI.Response) -> void:
	if _error:
		return
	config_model = _response.transformed.result.kinds
	config_model = model_merge_base_classes(config_model)
	emit_signal("model_ready")


func model_merge_base_classes(_model:Dictionary):
	var merged_model : Dictionary = _model.duplicate(true)
	for c in merged_model.keys():
		var merged_properties : Array = properties_from_base_classes(merged_model[c], [], _model)
		if not merged_properties.empty() and merged_model[c].has("properties"):
			merged_model[c].properties.append_array(merged_properties)
	return merged_model


func properties_from_base_classes(class_dict:Dictionary, merged_properties:Array, _unmodified_model:Dictionary):
	if class_dict.has("properties") and class_dict.has("bases") and not class_dict.bases.empty():
		for base_class in class_dict.bases:
			if _unmodified_model.has(base_class) and _unmodified_model[base_class].has("properties"):
				merged_properties.append_array(_unmodified_model[base_class].properties)
			merged_properties = properties_from_base_classes(_unmodified_model[base_class], merged_properties, _unmodified_model)
	return merged_properties


func _on_get_configs_done(_error:int, _response:ResotoAPI.Response) -> void:
	if _error:
		return
	
	# if the model is not received yet, yield for the signal
	if config_model.empty():
		yield(self, "model_ready")
	
	show()
	config_keys = _response.transformed.result
	
	if config_keys.empty():
		_g.emit_signal("add_toast", "Could not get Configs from Resoto Core!", "", 1, self)
		return
	
	create_config_tree(config_keys)
	if not config_keys.has(active_config_key):
		active_config_key = DefaultConfig
	
	emit_signal("config_list_refreshed")


func create_config_tree(_config_keys:Array):
	var tree : Tree = $"%ConfigSelectionTree"
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	for string in _config_keys:
		var current_parent = root
		var keys = string.split(".")
		for i in keys.size():
			if i == 0:
				continue
			else:
				var already_exists = false
				for pc in tree_get_item_children(current_parent):
					if pc.get_text(0) == keys[i]:
						current_parent = pc
						already_exists = true
						break
				if not already_exists:
					var new_cat = tree.create_item(current_parent)
					if i == keys.size()-1:
						new_cat.set_text(0, keys[i])
						new_cat.set_icon(0, load("res://assets/icons/icon_128_settings.svg"))
						new_cat.set_icon_max_width(0, 20)
						new_cat.set_icon_modulate(0, Style.col_map[Style.c.LIGHT])
					else:
						new_cat.set_text(0, keys[i])
						new_cat.set_custom_color(0, Style.col_map[Style.c.NORMAL])
						new_cat.set_icon(0, load("res://assets/icons/icon_128_folder.svg"))
						new_cat.set_selectable(0, false)
						new_cat.set_icon_max_width(0, 20)
						new_cat.set_icon_modulate(0, Style.col_map[Style.c.NORMAL])
					if DEFAULT_COLLAPSED_CATEGORIES.has(keys[i]):
						new_cat.collapsed = true
					new_cat.set_metadata(0, string)
					if string == active_config_key:
						new_cat.select(0)
					current_parent = new_cat
				else:
					continue
	$"%ConfigLabel".text = "Config: %s" % active_config_key


func _on_ConfigSelectionTree_item_selected():
	var tree : Tree = $"%ConfigSelectionTree"
	var selected_tree_item :TreeItem = tree.get_selected()
	open_configuration(selected_tree_item.get_metadata(0))
	$"%ConfigLabel".text = "Config: %s" % active_config_key


func tree_get_item_children(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children


func open_configuration(_config_key:String) -> void:
	# Cancel the old request if configs are changed in quick succession
	if config_req:
		config_req.cancel()
	active_config_key = _config_key
	config_page = null
	active_config = {}
	for c in content.get_children():
		c.queue_free()
	config_req = API.get_config_id(self, _config_key)


func _on_get_config_id_done(_error:int, _response:ResotoAPI.Response, _config_key:String) -> void:
	if _error:
		if _error == ERR_PRINTER_ON_FIRE:
			return
		# Handle eventual error... if we arrive here, any other error should be
		# extremely unlikely
		return
	active_config = _response.transformed.result
	build_config_page()


func build_config_page():
	if not use_raw_mode:
		$"%RawViewModeButton".set_pressed(false, false)
		$"%RawViewModeButton".disabled = false
		$"%RawViewMapTitle".modulate.a = 1
	var new_config_page = add_new_config_page(active_config_key)
	new_config_page.set_meta("main_level", true)
	new_config_page.key = active_config_key
	new_config_page.config_component = self
	new_config_page.kind = active_config_key
	new_config_page.value = active_config
	var new_elements = []
	
	# If the config is completely empty, just add a raw json display
	if active_config.keys().empty():
		$"%RawViewModeButton".set_pressed(true, false)
		$"%RawViewModeButton".disabled = true
		$"%RawViewMapTitle".modulate.a = 0.3
		var new_element = add_element("_", "", {}, new_config_page, false)
		new_elements.append(new_element)
	else:
		var dict_key = active_config.keys()[0]
		var new_element = add_element(dict_key, dict_key, active_config, new_config_page, false)
		if typeof(new_element) == TYPE_ARRAY:
			new_elements.append_array(new_element)
		else:
			new_elements.append(new_element)
	
	new_config_page.content_elements = new_elements
	
	# If there is only one main key in the dictionary / config, expand it when showing the tab.
	var count_complex:= 0
	var first_complex:Node= null
	for c in new_config_page.get_children():
		if c.name.begins_with("Complex_"):
			c.make_top_level_headline()
			first_complex = c
			count_complex += 1
	
	# If there is only one top level "Complex" type, expand it right away
	# E.g. resoto.core (resotocore), resoto.core.commands (custom_commands)
	if count_complex == 1:
		first_complex.set_expand_fixed()
	config_page = new_config_page
	emit_signal("pages_built")


func add_new_config_page(_title:String) -> Node:
	var new_config_page = preload("res://components/config/config_templates/component_config_template_config_page.tscn").instance()
	new_config_page.name = "ConfigPage_" + _title
	content.add_child(new_config_page)
	return new_config_page


func save_config() -> void:
	var json_config_result = convert_active_config_to_string()
	if json_config_result.error != OK:
		_g.emit_signal("add_toast", "Error saving configuration.", "", 1, self)
		return
	
	config_put_req = API.put_config_id(self, active_config_key, json_config_result.string)
	Analytics.event(Analytics.EventsConfig.EDIT, {"config-name": active_config_key})


func convert_active_config_to_string() -> Dictionary:
	var _error : int = OK
	var result : Dictionary = {"error" : _error, "dict" : null, "string" : ""}
	if config_page == null:
		result.error = FAILED
		return result
	var new_config:Dictionary = {}
	for config_element in config_page.content_elements:
		if "key" in config_element:
			new_config[config_element.key] = config_element.value
		else:
			new_config = config_element.value
		if "value_creation_error" in config_element:
			if config_element.value_creation_error:
				result.error = FAILED
				return result
	result.dict = new_config
	var json_string = JSON.print(new_config)
	if json_string.begins_with("{\"\":"):
		json_string = json_string.trim_prefix("{\"\":").trim_suffix("}")
	
	result.string = json_string
	return result


func _on_put_config_id_done(_error, _response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error saving configuration.", "", 1, self)
		return
	
	if typeof(_response.transformed.result) == TYPE_STRING and _response.transformed.result.begins_with("Error"):
		var error_total:Array = _response.transformed.result.split("\n")
		var error_title = error_total[0]
		var error_description = _response.transformed.result.lstrip(error_total[0] + "\n").rstrip("\n")
		_g.emit_signal("add_toast", error_title, error_description, 1, self, 10)
		return
	
	
	var config_revision:String = ""
	if "Resoto-Config-Revision" in _response.headers:
		config_revision = "Revision: " + _response.headers["Resoto-Config-Revision"]
	_g.emit_signal("add_toast", "Configuration updated successfully.", config_revision, 0, self)
	emit_signal("config_updated")


# first element in array is true if it is a fqn element.
func find_in_model(_id:String) -> Array:
	for model_key in config_model.keys():
		if model_key == _id:
			return [true, config_model[model_key]]
	return [false, null]


func is_fqn(_id:String) -> bool:
	return config_model.keys().has(_id) and config_model[_id].has("properties")
	# old variant, top is shorter and should result the same
#	return model.keys().has(_id) and not BASE_KINDS.has(_id) and not model[_id].has("enum")


func find_in_properties(_properties:Array, _id:String) -> Dictionary:
	for prop in _properties:
		if prop.name == _id:
			return prop
	return {}


func add_element(_name:String, kind:String, _property_value, _parent:Control, default:bool):
	var model_search = find_in_model(kind)
	var model = model_search[1]
	
	if BASE_KINDS.has(kind) and not use_raw_mode:
		# Create a new "Simple"
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_simple(_name, _property_value, kind, simple_property, _parent, default)
	
	elif kind.begins_with("dictionary") and not kind.ends_with("[]") and not use_raw_mode:
		# Create a new Dictionary 
#		print("=> Dict :", _name, ">", kind)
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_dict(_name, kind, _property_value, simple_property, _parent, default)
	
	elif kind.ends_with("[]") and not use_raw_mode:
		# Create a new Array
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_array(_name, _property_value, kind, simple_property, _parent, default)
	
	elif model and model.has("enum") and not use_raw_mode:
		# Create a new Enum selection field
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_enum(_name, _property_value, kind, simple_property, model.enum, _parent, default)
	
	elif model and model.has("properties") and not use_raw_mode:
		# Create a new Complex, either by scratch or with values.
		var new_elements:Array = []
		if not default:
			# the new element has values, it's not a blank new value.
			for key in _property_value.keys():

				var element = _property_value[key]
				var element_property = find_in_properties(model.properties, key)
				
				if element_property.empty():
					var element_model_search = find_in_model(key)
					if element_model_search[1] != null:
						var element_model = element_model_search[1].properties
						var element_kind:String = key if not (element_model and element_model.has("kind")) else element_model.kind
						new_elements.append( create_complex(key, element_kind, element, element_model, _parent, default) )
					else:
						# If there is a problem with the model / data, use the raw view as fallback
						_g.emit_signal("add_toast", "Config Model Error", "The current configuration has properties not described in the model, fallback raw view will be used.", 1, self)
						use_raw_mode = true
						$"%RawViewModeButton".set_pressed(true, false)
						$"%RawViewModeButton".disabled = true
						$"%RawViewMapTitle".modulate.a = 0.3
						open_configuration(active_config_key)
						return
				else:
					if is_fqn(element_property.kind):
						new_elements.append( create_complex(key, element_property.kind, element, element_property, _parent, default) )
					else:
						new_elements.append( add_element(key, element_property.kind, element, _parent, default) )
		else:
			# the element is "default = true", meaning it needs to be created from scratch.
			for element_property in model.properties:
				if is_fqn(element_property.kind):
					new_elements.append( create_complex(element_property.name, element_property.kind, null, element_property, _parent, default) )
				else:
					new_elements.append( add_element(element_property.name, element_property.kind, null, _parent, default) )
			pass
		return new_elements
	else:
		var error_message = ""
		if not use_raw_mode:
			error_message = "Configuration was not found in model.\nDisplaying configurations in raw JSON:"
			$"%RawViewModeButton".set_pressed(true, false)
			$"%RawViewModeButton".disabled = true
			$"%RawViewMapTitle".modulate.a = 0.3
		use_raw_mode = false
		return create_custom(error_message, _property_value, _parent)


func get_kind_type(kind:String) -> String:
	if BASE_KINDS.has(kind):
		return "simple"
	elif kind.begins_with("dictionary"):
		return "dict"
	elif "[]" in kind:
		return "array"
	else:
		return "complex"


func create_custom(_text:String, _property_value, _parent:Control):
	var new_custom = preload("res://components/config/config_templates/component_config_template_custom_config.tscn").instance()
		
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_custom)
	else:
		_parent.add_child(new_custom)
	
	new_custom.value = _property_value
	if _text != "":
		new_custom.get_node("MessageLabel").text = _text
	else:
		new_custom.get_node("MessageLabel").hide()
	
	return new_custom
	

func create_complex(_name:String, kind:String, _property_value, properties, _parent:Control, default:bool):
	if properties == null:
		_g.emit_signal("add_toast", "Error on config creation.", "Complex not found in model: "+ str(_name), 1, self)
		prints("ERROR: Complex not found in model:", _name)
		return
	
	var complex_model_search = find_in_model(kind)
	var complex_properties = complex_model_search[1]
	
	var new_complex = preload("res://components/config/config_templates/component_config_template_complex.tscn").instance()
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_complex, "_on_key_update")
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_complex)
	else:
		_parent.add_child(new_complex)
	
	new_complex.get_node("HeaderBG/Header/Top/Name").text = _name.capitalize()
	new_complex.descriptions_as_hints = descriptions_as_hints
	
	new_complex.set_meta("attach", new_complex.get_node("Margin/Content"))
	new_complex.config_component = self
	new_complex.name = "Complex_" + _name
	new_complex.key = _name
	new_complex.default = default
	new_complex.model = complex_properties
	new_complex.kind = kind
	new_complex.kind_type = get_kind_type(kind)
	new_complex.value = _property_value
	
	if properties.has("description"):
		new_complex.description = properties.description
		new_complex.required = properties.required
	else:
		new_complex.description = ""
	
	return new_complex


func create_simple(_name:String, _value, _kind, _properties, _parent:Control, default:bool):
#	prints("===> Create simple element:", _name, "| Parent:", _parent.name)#, _properties)
	var new_value = preload("res://components/config/config_templates/component_config_template_simple.tscn").instance()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_value)
	else:
		_parent.add_child(new_value)
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_value, "_on_key_update")
	
	new_value.descriptions_as_hints = descriptions_as_hints
	new_value.kind = _kind
	new_value.value = _value
	new_value.name = "Simple_" + _name
	new_value.set_default(default)
	
	
	# if _properties is null, the created node represents a array element.
	if _properties:
		new_value.key = _properties.name
		new_value.description = _properties.description
		new_value.required = _properties.required
	else:
		new_value.key = _name
		new_value.description = ""
		new_value.required = false
	
	return new_value


func create_enum(_name:String, _value, _kind, _properties, _enum_values, _parent:Control, default:bool):
#	prints("===> Create simple element:", _name, "| Parent:", _parent.name)#, _properties)
	var new_value = preload("res://components/config/config_templates/component_config_template_enum.tscn").instance()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_value)
	else:
		_parent.add_child(new_value)
	
	new_value.descriptions_as_hints = descriptions_as_hints
	new_value.enum_values = _enum_values
	new_value.kind = _kind
	new_value.value = _value
	new_value.name = "Enum_" + _name
	new_value.set_default(default)
	
	
	# if _properties is null, the created node represents a array element.
	if _properties:
		new_value.key = _properties.name
		new_value.description = _properties.description
		new_value.required = _properties.required
	else:
		new_value.key = _name
		new_value.description = ""
		new_value.required = false
	
	return new_value


func create_array(_name:String, _value, _kind, _properties, _parent:Control, default:bool):
	var kind = _kind.replace("[]", "")
	var new_array_container = preload("res://components/config/config_templates/component_config_template_elements_container.tscn").instance()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_array_container)
	else:
		_parent.add_child(new_array_container)
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_array_container, "_on_key_update")
	
	new_array_container.descriptions_as_hints = descriptions_as_hints
	new_array_container.default = default
	new_array_container.title = _name.capitalize()
	new_array_container.kind = kind
	new_array_container.name = "Array_" + _name
	new_array_container.config_component = self
	new_array_container.key = _name
	
	var complex_model_search = find_in_model(kind)
	var complex_properties = complex_model_search[1]
	if complex_properties:
		new_array_container.model = complex_properties
	
	
	# if _properties is null, the created node represents a array element.
	if _properties:
		new_array_container.key = _properties.name
		if _properties.has("description"):
			new_array_container.description = _properties.description
		new_array_container.required = _properties.required
	else:
		new_array_container.description = ""
		new_array_container.required = false
	
	if _value == null:
		new_array_container.is_null = true
	new_array_container.value = _value
	
	return new_array_container


func create_dict(_name:String, _kind, _value, _properties, _parent:Control, default:bool):
	var new_dict_container = preload("res://components/config/config_templates/component_config_template_elements_container.tscn").instance()
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_dict_container)
	else:
		_parent.add_child(new_dict_container)
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_dict_container, "_on_key_update")
	
	var dict_element_kind = _kind.trim_prefix("dictionary[string,").trim_suffix("]").dedent()
	
	new_dict_container.default = default
	new_dict_container.kind_type = "dict"
	new_dict_container.model = {"fqn": dict_element_kind}
	new_dict_container.title = _name
	new_dict_container.kind = "dict"
	new_dict_container.name = "Dict_" + _name
	new_dict_container.config_component = self
	new_dict_container.key = _name
	new_dict_container.descriptions_as_hints = descriptions_as_hints
	
	# if _properties is null, the created node represents a array element.
	if _properties:
		new_dict_container.key = _properties.name
		if _properties.has("description"):
			new_dict_container.description = _properties.description
		new_dict_container.required = _properties.required
	else:
		new_dict_container.description = ""
		new_dict_container.required = false
	
	if _value == null:
		new_dict_container.is_null = true
	new_dict_container.value = _value
	
	return new_dict_container


func build_simple(elements):
	if elements.empty():
		return null
	return elements[0].value


func build_array(elements):
	var new_array = []
	for element in elements:
		if typeof(element.value) == TYPE_ARRAY:
			new_array.append_array(element.value)
		else:
			new_array.append(element.value)
	return new_array


func build_dict(elements):
	var new_dict = {}
	for element in elements:
		new_dict[element.key] = element.value
	return new_dict


func _on_SaveConfigButton_pressed() -> void:
	save_config()


func _on_LoadConfigFromCoreButton_pressed() -> void:
	open_configuration(active_config_key)


func _on_CloseConfigButton_pressed():
	emit_signal("close_config")


func _on_ConfigCombo_option_changed(option):
	API.get_configs(self)
	yield(self, "config_list_refreshed")
	var config_index = config_keys.find(option)

	if config_index == -1:
		_g.emit_signal("add_toast", "Config not found", "The configuration you tried to open does not exist", 2, self)
		return
	open_configuration(option)
	emit_signal("config_changed", option)


func _on_AddConfigButton_pressed():
	var add_confirm_popup = _g.popup_manager.show_input_popup(
		"Rename Configuration",
		"Enter a name for the new configuration:",
		"new_config",
		"Accept", "Cancel")
	add_confirm_popup.connect("response_with_input", self, "_on_add_confirm_response", [], CONNECT_ONESHOT)


func _on_add_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		# Check if a config with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		API.get_configs(self)
		yield(self, "config_list_refreshed")
		if config_keys.has(_value):
			_g.emit_signal("add_toast", "Config Creation failed", "A Configuration with that name already exists in Resoto Core", 1, self)
			return
		# Show loading animation
		config_put_req = API.put_config_id(self, _value, "{\"purple\":\"sheep\"}")
		Analytics.event(Analytics.EventsConfig.NEW)
		yield(self, "config_updated")
		active_config_key = _value
		load_configs()


func _on_DeleteConfigButton_pressed():
	# Dangerzone!
	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		"Delete Configuration?",
		"Do you want to delete the following configuration:\n`%s`\n\nThis operation can not be undone!" % active_config_key,
		"Delete", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String, _double_confirm:=false):
	if _response == "left":
		if ProtectedConfigs.has(active_config_key) and not _double_confirm:
			_g.popup_manager.on_popup_close()
			yield(_g.popup_manager, "popup_gone")
			var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
			"Delete Configuration?",
			"`%s` is a sytem configuration, are you sure you want to delete it anyway?\n\nThis operation can not be undone!" % active_config_key,
			"Delete", "Cancel")
			
			delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [true], CONNECT_ONESHOT)
			return
		
		API.delete_config_id(self, active_config_key)
		Analytics.event(Analytics.EventsConfig.DELETE)


func _on_delete_config_id_done(_error: int, _response):
	load_configs()
	yield(self, "pages_built")
	if rename_new_name != "":
		active_config_key = rename_new_name
	rename_new_name = ""


func _on_DuplicateConfigButton_pressed():
	duplicate_new_name = ""
	var duplicate_confirm_popup = _g.popup_manager.show_input_popup(
		"Duplicate Configuration",
		"Enter a new name for the duplicate of:\n`%s`" % active_config_key,
		active_config_key+"_duplicate_" + str(OS.get_unix_time()),
		"Accept", "Cancel")
	duplicate_confirm_popup.connect("response_with_input", self, "_on_duplicate_confirm_response", [], CONNECT_ONESHOT)


var duplicate_new_name : String = ""
func _on_duplicate_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		# Check if a config with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		API.get_configs(self)
		yield(self, "config_list_refreshed")
		if config_keys.has(_value):
			_g.emit_signal("add_toast", "Duplicating Config failed", "A Configuration with that name already exists in Resoto Core", 1, self)
			return
		
		duplicate_new_name = _value
		var json_config_result = convert_active_config_to_string()
		if json_config_result.error != OK:
			_g.emit_signal("add_toast", "Error duplicating configuration.", "", 1, self)
			return
		
		config_put_req = API.put_config_id(self, duplicate_new_name, json_config_result.string)
		Analytics.event(Analytics.EventsConfig.DUPLICATE)
		yield(self, "config_updated")
		active_config_key = duplicate_new_name
		duplicate_new_name = ""
		load_configs()


func _on_RenameConfigButton_pressed():
	rename_new_name = ""
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Rename Configuration",
		"Renaming will omit changes (Save first!)\nEnter a new name for the configuration:\n`%s`" % active_config_key,
		active_config_key,
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_rename_confirm_response", [], CONNECT_ONESHOT)


var rename_new_name : String= ""
func _on_rename_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		if active_config_key == _value:
			# No name change happened
			return
		# Check if a config with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		API.get_configs(self)
		yield(self, "config_list_refreshed")
		if config_keys.has(_value):
			_g.emit_signal("add_toast", "Renaming failed", "A Configuration with that name already exists in Resoto Core", 1, self)
			return
		
		rename_new_name = _value
		config_put_req = API.put_config_id(self, rename_new_name, JSON.print(active_config))
		API.delete_config_id(self, active_config_key, "_on_delete_config_id_done")
		yield(self, "config_updated")
		active_config_key = rename_new_name


func _on_RawViewModeButton_toggled(_pressed):
	use_raw_mode = _pressed
	open_configuration(active_config_key)
