extends Control

const SIMPLE_KINDS:Array = ["string", "int64", "boolean"]

signal ModelReady
signal CloseConfig

var config_model_req: ResotoAPI.Request
var core_config_req: ResotoAPI.Request
var core_config_put_req: ResotoAPI.Request

var model:Dictionary
var model_top_level:Array
var config:Dictionary
var ui_config:Dictionary

var tabs_content: Dictionary = {}
var tabs_content_keys: Array = []
var _active_tab_id: int = -1

onready var tabs: Tabs = find_node("Tabs")
onready var content = find_node("Content")

# Template Elements
onready var TemplateConfigTab = find_node("ElementConfigTab")
onready var TemplateMainLevel = find_node("ElementMainLevel")
onready var TemplateComplex = find_node("ElementComplex")
onready var TemplateSimple = find_node("ElementSimple")
onready var TemplateArray = find_node("ElementArray")
onready var TemplateDict = find_node("ElementDict")


func load_config():
	config_model_req = API.get_config_model(self)
	yield(self, "ModelReady")
	core_config_req = API.get_config_id(self)


func _on_get_config_model_done(_error, _response):
	model = _response.transformed.result.kinds
	emit_signal("ModelReady")


func _on_get_config_id_done(_error, _response):
	config = _response.transformed.result.resotocore
	build_config_pages()
	change_active_tab(0, true)


func build_config_pages():
	ui_config["resotocore"] = {}
	for key in config.keys():
		var new_tab = add_new_tab(key)
		new_tab.set_meta("main_level", true)
		add_element(key, config[key], new_tab, ui_config["resotocore"])
	tabs_content_keys = tabs_content.keys()
	update_size()


func construct_config_json():
	var new_config = ui_config.duplicate(true)
	collect_values(new_config)
	var json_config = JSON.print(new_config)
#	print_dict(new_config, 0)
	core_config_put_req = API.put_config_id(self, "resoto.core", json_config)


func _on_put_config_id_done(_error, _response):
	pass
#	prints(_error, _response.transformed, _response.headers)
#	var status_code:int
#	var headers:Dictionary
#	var body:PoolByteArray
#	var transformed:Dictionary


func collect_values(dict:Dictionary):
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			collect_values(dict[key])
		elif dict[key].has_method("get_value"):
			dict[key] = dict[key].get_value()


func print_dict(_dict:Dictionary, _depth:int):
	var _spacing = ""
	for i in _depth:
		_spacing += "  "
	for d in _dict.keys():
		prints(_spacing, d)
		if typeof(_dict[d]) == TYPE_DICTIONARY:
			print_dict(_dict[d], _depth+1)
		else:
			prints(_spacing + "   ", _dict[d])


func find_in_model(_id:String):
	for model_cat in model.values():
		if "properties" in model_cat:
			for prop in model_cat["properties"]:
				if prop.name == _id:
					return prop

func find_in_model_dict(_id:String):
	for model_cat in model.values():
		if model_cat.has("fqn"):
			if model_cat.fqn == _id:
				return model_cat.properties[0]


func add_element(_name:String, _property_value, _parent:Control, _parent_dict:Dictionary):
	var properties = find_in_model(_name)
	
	if properties:
		var kind = properties.kind
		if SIMPLE_KINDS.has(kind):
			# The element is a simple field
			create_simple(_name, _property_value, kind, properties, _parent, _parent_dict)
			return
		elif "[]" in properties.kind:
			# The element is an array of dictionary
			create_array(_name, _property_value, kind, properties, _parent, _parent_dict)
			return
		elif "[" in properties.kind:
			create_dict(_name, _property_value, kind, properties, _parent, _parent_dict)
			return
	
	if _parent.has_meta("model"):
		# The element is a complex type
		var parent_kind = find_in_model(_parent.get_meta("model").kind)
		create_complex(_name, _property_value, parent_kind, _parent, _parent_dict)


func create_complex(_name:String, _property_value, _parent_kind, _parent:Control, _parent_dict:Dictionary):
	_parent_dict[_name] = {}
	var new_complex = TemplateComplex.duplicate()
	var category_model = find_in_model(_name)
	
	if category_model:
		if _parent.has_meta("main_level"):
			new_complex = TemplateMainLevel.duplicate()
#			new_complex.set_meta("children_expanded", true)
		else:
			new_complex.set_meta("attach", new_complex.get_node("Margin/Content"))
			new_complex.get_node("Header/Top/Name").text = _name.capitalize()
			new_complex.get_node("Header/Description").text = category_model.description
		new_complex.name = "Complex_" + _name
		new_complex.set_meta("model", category_model)
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_complex)
	else:
		_parent.add_child(new_complex)
	
	if typeof(_property_value) == TYPE_DICTIONARY:
		for sub_key in _property_value.keys():
			add_element(sub_key, _property_value[sub_key], new_complex, _parent_dict[_name])
	else:
		for sub_key in _property_value:
			add_element(sub_key, sub_key, new_complex, _parent_dict[_name])


func create_simple(_name:String, _value, _kind, _properties, _parent:Control, _parent_dict:Dictionary):
	var new_value = TemplateSimple.duplicate()
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_value)
	else:
		_parent.add_child(new_value)
	new_value.required = _properties.required
	new_value.kind = _kind
	new_value.description = _properties.description
	new_value.value = _value
	new_value.var_name = _name
	_parent_dict[_name] = new_value


func create_array(_name:String, _value, _kind, _properties, _parent:Control, _parent_dict:Dictionary):
	var array_model = find_in_model(_name)
	var new_array_wrapper = TemplateComplex.duplicate()
	new_array_wrapper.get_node("Header/Top/Name").text = _name.capitalize()
	new_array_wrapper.get_node("Header/Description").text = array_model.description
	new_array_wrapper.name = "ArrayWrapper_" + _name
	new_array_wrapper.start_expanded = _parent.has_meta("children_expanded")
	
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_array_wrapper)
	else:
		_parent.add_child(new_array_wrapper)
	
	var new_array = TemplateArray.duplicate()
	new_array_wrapper.get_node("Margin/Content").add_child(new_array)
	
	new_array.title = _name.capitalize()
	new_array.title_node = new_array_wrapper.get_node("Header/Top/Name")
	new_array.kind = _kind.replace("[]", "")
	new_array.value = _value
	_parent_dict[_name] = new_array


func create_dict(_name:String, _value, _kind, _properties, _parent:Control, _parent_dict:Dictionary):
	var dictionary_element_kind:String = _kind.trim_prefix("dictionary[").trim_suffix("]").split(",")[1].dedent()
	var dict_wrapper_model = find_in_model(_name)
	var new_dict_wrapper = null
	
	if not _parent.has_meta("main_level"):
		new_dict_wrapper = TemplateComplex.duplicate()
		new_dict_wrapper.get_node("Header/Top/Name").text = _name.capitalize()
		new_dict_wrapper.get_node("Header/Description").text = dict_wrapper_model.description.capitalize()
		new_dict_wrapper.name = "ArrayWrapper_" + _name
		new_dict_wrapper.start_expanded = _parent.has_meta("children_expanded")
	else:
		new_dict_wrapper = TemplateMainLevel.duplicate()
		
	if _parent.has_meta("attach"):
		_parent.get_meta("attach").add_child(new_dict_wrapper)
	else:
		_parent.add_child(new_dict_wrapper)
	
	
	var dict_model = find_in_model_dict(dictionary_element_kind)
	_parent_dict[_name] = {}
	
	
	for key in _value.keys():
		var element_value:String
		if typeof(_value[key]) == TYPE_DICTIONARY:
			for i in _value[key].values():
				element_value = i
		else:
			element_value = _value[key]
		
		var new_dict = TemplateDict.duplicate()
		if not _parent.has_meta("main_level"):
			new_dict_wrapper.get_node("Margin/Content").add_child(new_dict)
		else:
			new_dict_wrapper.add_child(new_dict)
		new_dict.get_node("Key").text = key.capitalize()
		
		var new_value = TemplateSimple.duplicate()
		new_value.required = dict_model.required
		new_value.kind = dict_model.kind
		new_value.description = dict_model.description
		new_value.value = element_value
		new_value.var_name = dict_model.name.capitalize()
		
		new_dict.get_node("Container").add_child(new_value)
		
		_parent_dict[_name][key] = { dict_model.name : new_value }


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


func add_new_tab(_title:String):
	var new_element = null
	tabs.add_tab(_title.capitalize())
	var category_model = find_in_model(_title)
	if category_model:
		var new_config_tab = TemplateConfigTab.duplicate()
		new_config_tab.get_node("Description").text = category_model.description
		new_config_tab.set_meta("model", category_model)
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


func hide_all_tabs():
	for tab in tabs_content.values():
		tab.hide()


func _on_Tabs_tab_changed(tab:int) -> void:
	change_active_tab(tab)


func _on_SaveConfigButton_pressed():
	construct_config_json()


func _on_CloseConfigButton_pressed():
	emit_signal("CloseConfig")


func _on_Connect_connected():
	load_config()
