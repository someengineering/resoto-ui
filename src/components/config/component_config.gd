extends Control

# This configuration UI still needs a lot of clean up and testing!

const BASE_KINDS:Array = [
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

signal model_ready
signal close_config
signal config_received

var config_req: ResotoAPI.Request
var config_put_req: ResotoAPI.Request

var config_model:Dictionary
var config_keys:Array
var model_top_level:Array
var config:Dictionary
var config_tabs:Array = []

var tabs_content: Dictionary = {}
var tabs_content_keys: Array = []
var _active_tab_id: int = -1

onready var tabs: Tabs = find_node("Tabs")
onready var content = find_node("Content")

# Template Elements
onready var TemplateConfigTab = find_node("TemplateConfigTab")
onready var TemplateMainLevel = find_node("TemplateMainLevel")
onready var TemplateComplex = find_node("TemplateComplex")
onready var TemplateSimple = find_node("TemplateSimple")
onready var TemplateEnum = find_node("TemplateEnum")
onready var TemplateElementsContainer = find_node("TemplateElementsContainer")
onready var TemplateArrayElement = find_node("TemplateArrayElement")
onready var TemplateDict = find_node("TemplateDict")
onready var TemplateCustomConfig = find_node("TemplateCustomConfig")


func load_config() -> void:
	API.get_configs(self)


func _on_get_configs_done(_error, _response) -> void:
	config_keys = _response.transformed.result
	API.get_config_model(self)
	yield(self, "model_ready")
	
	for ck in config_keys:
		config_req = API.get_config_id(self, ck)
		yield(self, "config_received")
	
	_g.emit_signal("add_toast", "Configs received from Resoto Core.", "", 0)
	build_config_pages()


func _on_get_config_model_done(_error, _response) -> void:
	config_model = _response.transformed.result.kinds
	emit_signal("model_ready")


func _on_get_config_id_done(_error, _response, config_key) -> void:
	config[config_key] = _response.transformed.result
	emit_signal("config_received")


func build_config_pages() -> void:
	tabs_content.clear()
	config_tabs.clear()
	for i in tabs.get_tab_count():
		tabs.remove_tab(0)
	
	for c in content.get_children():
		c.queue_free()
	
	
	for key in config_keys:
		var new_tab = add_new_tab(key)
		new_tab.set_meta("main_level", true)
		new_tab.key = key
		new_tab.config_component = self
		new_tab.kind = key
		new_tab.value = config[key]
		var new_elements = []
		var dict_key = config[key].keys()[0]
		var new_element = add_element(dict_key, dict_key, config[key], new_tab, false)
		if typeof(new_element) == TYPE_ARRAY:
			new_elements.append_array(new_element)
		else:
			new_elements.append(new_element)
		new_tab.content_elements = new_elements
		config_tabs.append(new_tab)
	
	tabs_content_keys = tabs_content.keys()
	update_size()
	change_active_tab(0, true)


func save_config() -> void:
	var new_config:Dictionary = {}

	for config_element in config_tabs[_active_tab_id].content_elements:
		if "key" in config_element:
			new_config[config_element.key] = config_element.value
		else:
			new_config = config_element.value
			
		if "value_creation_error" in config_element:
			if config_element.value_creation_error:
				_g.emit_signal("add_toast", "Error saving configuration.", "", 1)
				return
	
	var selected_config = config_keys[_active_tab_id]
	var json_config = JSON.print(new_config)
	if json_config.begins_with("{\"\":"):
		json_config = json_config.trim_prefix("{\"\":").trim_suffix("}")
	config_put_req = API.put_config_id(self, selected_config, json_config)


func _on_put_config_id_done(_error, _response) -> void:
	if _error != 0:
		_g.emit_signal("add_toast", "Error saving configuration.", "", 1)
		return
	
	if typeof(_response.transformed.result) == TYPE_STRING and _response.transformed.result.begins_with("Error"):
		var error_total:Array = _response.transformed.result.split("\n")
		var error_title = error_total[0]
		var error_description = _response.transformed.result.lstrip(error_total[0] + "\n").rstrip("\n")
		_g.emit_signal("add_toast", error_title, error_description, 1, 10)
		return
	
	
	var config_revision:String = ""
	if "Resoto-Config-Revision" in _response.headers:
		config_revision = "Revision: " + _response.headers["Resoto-Config-Revision"]
	_g.emit_signal("add_toast", "Configuration updated successfully.", config_revision, 0)
	emit_signal("close_config")


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
	
	if BASE_KINDS.has(kind):
		# Create a new "Simple"
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_simple(_name, _property_value, kind, simple_property, _parent, default)
	
	elif kind.begins_with("dictionary"):
		# Create a new Dictionary 
#		print("=> Dict :", _name, ">", kind)
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_dict(_name, kind, _property_value, simple_property, _parent, default)
	
	elif "[]" in kind:
		# Create a new Array
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_array(_name, _property_value, kind, simple_property, _parent, default)
	
	elif model and model.has("enum"):
		# Create a new Enum selection field
		var simple_property = null
		if _parent.model and _parent.model.has("properties"):
			simple_property = find_in_properties(_parent.model.properties, _name)
		return create_enum(_name, _property_value, kind, simple_property, model.enum, _parent, default)
	
	elif model and model.has("properties"):
		# Create a new Complex, either by scratch or with values.
		var new_elements:Array = []
		if not default:
			# the new element has values, it's not a blank new value.
			for key in _property_value.keys():

				var element = _property_value[key]
				var element_property = find_in_properties(model.properties, key)
				
				if element_property.empty():
					var element_model_search = find_in_model(key)
					var element_model = element_model_search[1].properties
					var element_kind:String = key if not (element_model and element_model.has("kind")) else element_model.kind
					new_elements.append( create_complex(key, element_kind, element, element_model, _parent, default) )
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
		var error_message = "Configuration was not found in Model."
		error_message += "\nCustom Configurations are not renderable."
		error_message += "\n\nRaw JSON:\n"
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
	var new_custom = TemplateCustomConfig.duplicate()
		
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_custom)
	else:
		_parent.add_child(new_custom)
	
	new_custom.value = _property_value
	new_custom.get_node("MessageLabel").text = _text
	
	return new_custom
	

func create_complex(_name:String, kind:String, _property_value, properties, _parent:Control, default:bool):
	if properties == null:
		_g.emit_signal("add_toast", "Error on config creation.", "Complex not found in model: "+ str(_name), 1)
		prints("ERROR: Complex not found in model:", _name)
		return
	
	var complex_model_search = find_in_model(kind)
	var complex_properties = complex_model_search[1]
	
	var new_complex = TemplateComplex.duplicate()
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_complex, "_on_key_update")
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_complex)
	else:
		_parent.add_child(new_complex)
	
	new_complex.get_node("HeaderBG/Header/Top/Name").text = _name.capitalize()
	
	if properties.has("description"):
		new_complex.description = properties.description
		new_complex.required = properties.required
	else:
		new_complex.description = ""
		
	new_complex.set_meta("attach", new_complex.get_node("Margin/Content"))
	new_complex.config_component = self
	new_complex.name = "Complex_" + _name
	new_complex.key = _name
	new_complex.default = default
	new_complex.model = complex_properties
	new_complex.kind = kind
	new_complex.kind_type = get_kind_type(kind)
	new_complex.value = _property_value
	
	return new_complex


func create_simple(_name:String, _value, _kind, _properties, _parent:Control, default:bool):
#	prints("===> Create simple element:", _name, "| Parent:", _parent.name)#, _properties)
	var new_value = TemplateSimple.duplicate()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_value)
	else:
		_parent.add_child(new_value)
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_value, "_on_key_update")
	
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
	var new_value = TemplateEnum.duplicate()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_value)
	else:
		_parent.add_child(new_value)
	
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
	var new_array_container = TemplateElementsContainer.duplicate()
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_array_container)
	else:
		_parent.add_child(new_array_container)
	
	if _parent.has_signal("key_update"):
		_parent.connect("key_update", new_array_container, "_on_key_update")
	
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
	var new_dict_container = TemplateElementsContainer.duplicate()
	
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


func update_size() -> void:
	var tab_count =  tabs.get_tab_count()
	if tab_count == 0:
		tabs.rect_min_size.x = 0
		return
	
	var total_size_x : float = 0.0
	for i in tab_count:
		total_size_x += tabs.get_tab_rect(i).size.x
	tabs.rect_min_size.x = clamp(32 + total_size_x, 0, rect_size.x-30)


func change_tab_name(_new_name:String) -> void:
	tabs.set_tab_title(_active_tab_id, _new_name)
	update_size()


func add_new_tab(_title:String) -> Node:
	var new_element = null
	tabs.add_tab(_title)
	var new_config_tab = TemplateConfigTab.duplicate()
	new_config_tab.name = "Tab_" + _title
	content.add_child(new_config_tab)
	new_element = new_config_tab
	tabs_content[_title] = new_element
	return new_element


func change_active_tab(tab:int, update_tab:bool =false) -> void:
	_active_tab_id = tab
	if update_tab:
		tabs.current_tab = tab
	hide_all_tabs()
	if tabs_content.empty():
		return
	tabs_content[ tabs_content_keys[tab] ].show()


func hide_all_tabs() -> void:
	for tab in tabs_content.values():
		tab.hide()


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


func _on_Tabs_tab_changed(tab:int) -> void:
	change_active_tab(tab)


func _on_SaveConfigButton_pressed() -> void:
	save_config()


func _on_LoadConfigFromCoreButton_pressed() -> void:
	load_config()


func _on_CloseConfigButton_pressed():
	emit_signal("close_config")
