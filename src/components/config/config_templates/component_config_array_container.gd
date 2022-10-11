extends VBoxContainer
class_name ConfigComponentArray

const TemplateArrayElement = preload("res://components/config/config_templates/component_config_template_array_element.tscn")
const TemplateDictElement = preload("res://components/config/config_templates/component_config_template_dict_element.tscn")

var config_component:Node = null
var start_expanded:bool = false
var expanded:bool = true
var orig_size:int = 0
var required:bool = false setget set_required
var is_null:bool = false
var kind:String = ""
var kind_type = ""
var default = false
var model:Dictionary = {}
var key:String = ""
var title:String = "" setget set_title
var description:String = "" setget set_description
var value = null setget set_value, get_value
var content_elements:Array = []
var descriptions_as_hints:bool = true

onready var content = $Margin/Content/Elements
onready var null_value = $HeaderBG/Header/Top/VarValueIsNull


func _ready() -> void:
	if descriptions_as_hints:
		$HeaderBG/Header/Description.hide()
	_on_Expand_toggled(start_expanded)
	orig_size = $Margin.rect_size.y


func set_required(_value:bool) -> void:
	required = _value
	if is_null:
		$HeaderBG/Header/Top/ButtonAddValue.show()
	else:
		$HeaderBG/Header/Top/ButtonSetToNull.show()


func set_value(_value) -> void:
	value = _value
	if value == null:
		if default:
			_on_ButtonAddValue_pressed()
		else:
			set_to_null(true)
	else:
		refresh_elements()


func set_title(_new_title:String) -> void:
	title = _new_title
	$HeaderBG/Header/Top/Name.text = title
	if kind == "dict":
		$Margin/Content/AddButton.text = "Add key"
	else:
		$Margin/Content/AddButton.text = "Add element ("+ key.capitalize() +")"


func refresh_elements() -> void:
	if not self.is_inside_tree():
		yield(self, "ready")
	
	content_elements.clear()
	if kind == "dict":
		for c in content.get_children():
			if c.is_connected("delete", self, "_on_dict_element_delete"):
				c.disconnect("delete", self, "_on_dict_element_delete")
			if c.is_connected("duplicate", self, "_on_dict_element_duplicate"):
				c.disconnect("duplicate", self, "_on_dict_element_duplicate")
			c.queue_free()
	else:
		for c in content.get_children():
			if c.is_connected("delete", self, "_on_array_element_delete"):
				c.disconnect("delete", self, "_on_array_element_delete")
			if c.is_connected("duplicate", self, "_on_array_element_duplicate"):
				c.disconnect("duplicate", self, "_on_array_element_duplicate")
			c.queue_free()
	
	if kind == "dict":
		for dict_key in value.keys():
			var new_dict_element = TemplateDictElement.instance()
			content.add_child(new_dict_element)
			new_dict_element.model = model
			new_dict_element.name = "Dict_Element_" + str(dict_key)
			new_dict_element.config_component = config_component
			new_dict_element.set_meta("attach", new_dict_element.get_node("Box/Content"))
			new_dict_element.key = dict_key
			new_dict_element.connect("delete", self, "_on_dict_element_delete")
			new_dict_element.connect("duplicate", self, "_on_dict_element_duplicate")
			new_dict_element.value = value[dict_key]
			new_dict_element.default = false
			content_elements.append(new_dict_element)
	
	else:
		var new_elem_index:int = 0
		for element in value:
			var new_array_element = TemplateArrayElement.instance()
			content.add_child(new_array_element)
			new_array_element.model = model
			new_array_element.name = "Array_Element_" + str(new_elem_index)
			new_array_element.config_component = config_component
			new_array_element.set_meta("attach", new_array_element.get_node("Box/Content"))
			new_array_element.set_title(new_elem_index)
			new_array_element.connect("delete", self, "_on_array_element_delete", [new_elem_index])
			new_array_element.connect("duplicate", self, "_on_array_element_duplicate", [new_elem_index])
			new_array_element.value = element
			new_array_element.default = false
			content_elements.append(new_array_element)
			new_elem_index += 1
	update_title()


func update_title() -> void:
	if value != null:
		if kind == "dict":
			set_title(key + ": {" + str(value.size()) + "}")
		else:
			set_title(key.capitalize() + " [" + str(value.size()) + "]")
	else:
		set_title(key.capitalize())


func get_value():
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if is_null:
		return null
	else:
		if kind == "dict":
			var new_value:Dictionary = {}
			for i in content_elements.size():
				var element = content_elements[i]
				new_value[element.key] = element.value
			return new_value
		else:
			var new_value:Array = []
			for i in content_elements.size():
				var element = content_elements[i]
				new_value.append(element.value)
			return new_value


func set_description(_value:String) -> void:
	description = _value
	if descriptions_as_hints:
		$HeaderBG.hint_tooltip = "[b]Property:[/b]\n[code]%s[/code]\n\n%s" % [key, description]
		return
	$HeaderBG/Header/Description.text =  description


func _on_Expand_toggled(button_pressed) -> void:
	if is_null:
		return
	expanded = button_pressed
	$HeaderBG.self_modulate.a = 0.3 if not expanded else 1.0
	$HeaderBG/Header/Top/Expand.pressed = expanded
	$Margin.visible = expanded


func _on_ButtonSetToNull_pressed() -> void:
	set_to_null(true)


func set_to_null(to_null:bool) -> void:
	if to_null:
		_on_Expand_toggled(false)
		value = null
		set_title(key.capitalize())
		content_elements.clear()
		if content:
			for c in content.get_children():
				c.queue_free()
	is_null = to_null
	$HeaderBG/Header/Top/Expand.visible = !is_null
	$HeaderBG/Header/Top/VarValueIsNull.visible = is_null
	if not required:
		$HeaderBG/Header/Top/ButtonAddValue.visible = is_null
		$HeaderBG/Header/Top/ButtonSetToNull.visible = !is_null


func _on_ButtonAddValue_pressed() -> void:
	set_to_null(false)
	if kind == "dict":
		value = {}
	else:
		value = []
	_on_AddButton_pressed()


func _on_Header_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_Expand_toggled(!$HeaderBG/Header/Top/Expand.pressed)


func _on_AddButton_pressed() -> void:
	value = get_value()
	_on_Expand_toggled(true)
	
	var size:int = 0
	if value == null:
		size = 0
	else:
		size = value.size()
	
	if kind == "dict":
		var new_dict_element = TemplateDictElement.instance()
		content.add_child(new_dict_element)
		new_dict_element.model = model
		new_dict_element.name = "Dict_Element_" + str(size)
		var new_index = size
		while value.has("key_" + str(new_index)):
			new_index += 1
		new_dict_element.key = "key_" + str(size)
		new_dict_element.config_component = config_component
		new_dict_element.set_meta("attach", new_dict_element.get_node("Box/Content"))
		new_dict_element.default = true
		new_dict_element.value = null
		content_elements.append(new_dict_element)
		
	else:
		var new_array_element = TemplateArrayElement.instance()
		content.add_child(new_array_element)
		new_array_element.model = model
		new_array_element.name = "Array_Element_" + str(size)
		
		new_array_element.config_component = config_component
		new_array_element.set_meta("attach", new_array_element.get_node("Box/Content"))
		new_array_element.set_title(size)
		new_array_element.default = true
		new_array_element.value = null
		content_elements.append(new_array_element)
	
	value = get_value()
	refresh_elements()
	update_title()


func _on_array_element_delete(_array_pos:int) -> void:
	value = get_value()
	value.remove(_array_pos)
	refresh_elements()


func _on_array_element_duplicate(_array_pos:int) -> void:
	value = get_value()
	var duplicate = value[_array_pos]
	value.insert(_array_pos, duplicate)
	refresh_elements()


func _on_dict_element_delete(_array_key:String) -> void:
	value = get_value()
	value.erase(_array_key)
	refresh_elements()


func _on_dict_element_duplicate(_array_key:String) -> void:
	value = get_value()
	var duplicate = value[_array_key].duplicate(true)
	var new_key = _array_key + "_copy"
	while value.has(new_key):
		new_key += "_copy"
	
	value[new_key] = duplicate
	refresh_elements()


func _on_key_update(_new_key:String) -> void:
	key = _new_key
	update_title()
