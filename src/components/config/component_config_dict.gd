extends VBoxContainer
class_name ConfigComponentDict

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

onready var null_value = $Header/Top/VarValueIsNull


func _ready():
	_on_Expand_toggled(start_expanded)
	orig_size = $Margin.rect_size.y


func set_required(_value:bool):
	required = _value
	if is_null:
		$Header/Top/ButtonAddValue.show()
	else:
		$Header/Top/ButtonSetToNull.show()


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
	$Header/Description.text =  description


func _on_Expand_toggled(button_pressed):
	if button_pressed == expanded:
		return
	expanded = button_pressed
	$Header/HSeparator.visible = expanded
	$Header/Top/Expand.pressed = expanded
	$Margin.visible = expanded
	return


func _on_ButtonSetToNull_pressed():
	for c in $Margin/Content.get_children():
		c.queue_free()
	value = null
	$Header/Top/ButtonSetToNull.hide()
	$Header/Top/VarValueIsNull.show()
	$Header/Top/ButtonAddValue.show()


func _on_ButtonAddValue_pressed():
	prints("add", kind)


func _on_Header_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_Expand_toggled(!$Header/Top/Expand.pressed)
