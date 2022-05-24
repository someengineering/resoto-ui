extends VBoxContainer
class_name ConfigComponentComplex

var config_component:Node = null
var start_expanded:bool = false
var expanded:bool = true
var orig_size:int = 0
var required:bool = false setget set_required
var is_null:bool = false
var kind:String = ""
var kind_type = ""
var model:Dictionary = {}
var key:String = ""
var description:String = "" setget set_description
var value = null setget set_value, get_value
var content_elements:Array = []

onready var null_value = $HeaderBG/Header/Top/VarValueIsNull
onready var content = $Margin/Content


func _ready():
	_on_Expand_toggled(start_expanded)
	orig_size = $Margin.rect_size.y


func set_required(_value:bool):
	required = _value
	if is_null:
		$HeaderBG/Header/Top/ButtonAddValue.show()
	else:
		$HeaderBG/Header/Top/ButtonSetToNull.show()


func set_value(_value):
	value = _value
	if value == null:
		_on_ButtonSetToNull_pressed()
	var new_content_elements = config_component.add_element(key, kind, value, self, false)
	if typeof(new_content_elements) == TYPE_ARRAY:
		content_elements = new_content_elements
	else:
		content_elements = [new_content_elements]


func get_value():
	if not self.is_inside_tree():
		yield(self, "ready")
	
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


func set_description(_value:String):
	description = _value
	$HeaderBG/Header/Description.text =  description


func set_to_null(to_null:bool):
	if to_null:
		_on_Expand_toggled(false)
		value = null
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


func _on_ButtonSetToNull_pressed():
	set_to_null(true)


func _on_ButtonAddValue_pressed():
	set_to_null(false)
	var new_content_elements = config_component.add_element(key, kind, value, self, true)
	if typeof(new_content_elements) == TYPE_ARRAY:
		content_elements = new_content_elements
	else:
		content_elements = [new_content_elements]
	value = get_value()


func _on_key_update(_new_key:String):
	prints("Complex, key update of parent:", _new_key)


func _on_Expand_toggled(button_pressed):
	if button_pressed == expanded:
		return
	expanded = button_pressed
	$HeaderBG.self_modulate.a = 0.3 if not expanded else 1.0
#	$HeaderBG/Header/HSeparator.visible = expanded
	$HeaderBG/Header/Top/Expand.pressed = expanded
	$Margin.visible = expanded


func _on_Header_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_Expand_toggled(!$HeaderBG/Header/Top/Expand.pressed)
