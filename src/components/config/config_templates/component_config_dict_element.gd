extends Control

signal duplicate
signal delete
signal key_update

var config_component:Node = null
var model:Dictionary = {}
var value setget set_value, get_value
var content_elements:Array = []
var default:bool = false
var is_null:bool = false
var key:String = "" setget set_key

onready var null_value = $Box/Header/VarValueIsNull
onready var content = $Box/Content


func _on_DuplicateButton_pressed() -> void:
	emit_signal("duplicate", key)


func _on_DeleteButton_pressed() -> void:
	emit_signal("delete", key)


func set_key(_key:String) -> void:
	key = _key
	$Box/Header/VarKey.text = key


func set_value(_value) -> void:
	value = _value
	content_elements.clear()
	for c in content.get_children():
		c.queue_free()
	
	if value == null and not default:
		set_to_null(true)
		return
	
	var new_element = config_component.add_element(key, model.fqn, value, self, default)
	
	if default:
		default = false
	
	if typeof(new_element) == TYPE_ARRAY:
		content_elements = new_element
	else:
		content_elements = [new_element]


func get_value() -> void:
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if is_null:
		return null
	
	
	var kind_type = config_component.get_kind_type(model.fqn)
	
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
	var new_element = config_component.add_element(key, model.fqn, null, self, true)
	if typeof(new_element) == TYPE_ARRAY:
		content_elements = new_element
	else:
		content_elements = [new_element]
	value = get_value()


func _on_VarKey_text_changed(new_text:String) -> void:
	key = new_text
	if typeof(value) != TYPE_DICTIONARY:
		emit_signal("key_update", key)


func _on_key_update(_new_key:String) -> void:
	pass
