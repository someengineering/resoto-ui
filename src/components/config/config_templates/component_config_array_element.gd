extends Control

signal duplicate
signal delete

var config_component:Node = null
var model:Dictionary = {}
var value setget set_value, get_value
var content_elements:Array = []
var index := 0
var default:bool = false
var is_null:bool = false
var overridden: bool = false setget set_overridden

onready var null_value = $Box/Header/VarValueIsNull
onready var content = $Box/Content


func set_overridden(o : bool):
	overridden = 0
	$Box/Header/overriddenLabel.visible = o

func _on_DuplicateButton_pressed() -> void:
	emit_signal("duplicate")


func _on_DeleteButton_pressed() -> void:
	emit_signal("delete")


func set_title(_array_name:String, _index:int) -> void:
	index = _index
	if _array_name == "":
		$Box/Header/Description.text = "Index %s" % str(index)
	else:
		$Box/Header/Description.text = _array_name


func set_value(_value) -> void:
	value = _value
	content_elements.clear()
	for c in content.get_children():
		c.queue_free()
	
	if value == null and not default:
		set_to_null(true)
		return
	
	var new_element = null
	if not model.empty():
		new_element = config_component.add_element(model.fqn, model.fqn, value, self, default)
	else:
		new_element = config_component.create_custom("", _value, self)
	
	if default:
		default = false
	
	if typeof(new_element) == TYPE_ARRAY:
		content_elements = new_element
	else:
		content_elements = [new_element]
	for elem in content_elements:
		if "key" in elem and elem.key == "name":
			elem.connect("value_changed", self, "update_title_from_name")
			set_title(elem.value, index)
		if not model.empty() and config_component.BASE_KINDS.has(model.fqn):
			elem.connect("value_changed", self, "update_title_from_name")
			set_title(elem.value, index)


func update_title_from_name(_new_title:String):
	set_title(_new_title, index)


func get_value():
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if is_null:
		return null
	
	var kind_type = "any"
	if not model.empty():
		kind_type = config_component.get_kind_type(model.fqn)
	
	match kind_type:
		"simple":
			return config_component.build_simple(content_elements)
		"array":
			var new_value:Array = config_component.build_array(content_elements)
			return new_value
		"dict":
			var new_value:Dictionary = config_component.build_simple(content_elements)
			return new_value
		"complex":
			var new_value:Dictionary = config_component.build_dict(content_elements)
			return new_value
		"any":
			if content_elements.empty():
				return null
			return content_elements[0].value


func set_to_null(to_null:bool) -> void:
	is_null = to_null
	content.visible = !to_null
	null_value.visible = to_null
	$Box/Header/ButtonAddValue.visible = to_null
	$Box/Header/ButtonSetToNull.visible = !to_null


func _on_ButtonSetToNull_pressed() -> void:
	set_value(null)
	set_to_null(true)


func _on_ButtonAddValue_pressed() -> void:
	set_to_null(false)
	var new_element = config_component.add_element(model.fqn, model.fqn, null, self, true)
	if typeof(new_element) == TYPE_ARRAY:
		content_elements = new_element
	else:
		content_elements = [new_element]
	value = get_value()
