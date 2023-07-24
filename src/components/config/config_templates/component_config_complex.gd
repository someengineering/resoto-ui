extends VBoxContainer
class_name ConfigComponentComplex

var config_component:Node = null
var start_expanded:bool = false
var expanded:bool = true
var expand_locked:bool = false
var orig_size:int = 0
var required:bool = false setget set_required
var is_null:bool = false
var kind:String = ""
var kind_type = ""
var default:bool = false
var model:Dictionary = {}
var key:String = ""
var description:String = "" setget set_description
var value = null setget set_value, get_value
var content_elements:Array = []
var descriptions_as_hints:bool = true

onready var null_value = $HeaderBG/Header/Top/VarValueIsNull
onready var content = $Margin/Content


func _draw():
	if is_null and required:
		var rect = get_rect()
		rect.position = -2*Vector2.ONE
		rect = rect.grow(5)
		$"%MissingRequiredLabel".show()
		draw_rect(rect, Color("#f44444"), false, 1.0)
	else:
		$"%MissingRequiredLabel".hide()


func _ready() -> void:
	Style.add($HeaderBG/Header/Top/Expand, Style.c.LIGHT)
	
	expand(start_expanded)
	orig_size = $Margin.rect_size.y


func expand(_expand:bool):
	if expand_locked:
		$Margin.visible = true
		return
	expanded = _expand
	$HeaderBG.self_modulate.a = 0.3 if not expanded else 1.0
	$HeaderBG/Header/Top/Expand.pressed = expanded
	$Margin.visible = expanded


func make_top_level_headline():
	$HeaderBG/Header/Top/Name.theme_type_variation = "Label_24"


func show_description(_show:bool) -> void:
	$"%DescriptionContainer".visible = _show if description != "" else false


func set_description(_value:String) -> void:
	description = _value
	$"%DescriptionContainer".visible = description != ""
	$"%Description".text = description


func set_expand_fixed():
	expand_locked = true
	$HeaderBG.self_modulate.a = 1.0
	$Margin.visible = true
	$HeaderBG/Header/Top/Expand.hide()
	if $HeaderBG/Header.is_connected("gui_input", self, "_on_Header_gui_input"):
		$HeaderBG/Header.disconnect("gui_input", self, "_on_Header_gui_input")


func set_required(_value:bool) -> void:
	required = _value
	if required:
		if is_null:
			$HeaderBG/Header/Top/ButtonAddValue.show()
	$HeaderBG/Header/Top/ButtonSetToNull.hide()


func set_value(_value) -> void:
	value = _value
	
	if value == null:
		_on_ButtonSetToNull_pressed()
	else:
		for property in model.properties:
			if not property.name in value:
				value[property.name] = null
	
	var new_content_elements = config_component.add_element(key, kind, value, self, false)
	if typeof(new_content_elements) == TYPE_ARRAY:
		content_elements = new_content_elements
	else:
		content_elements = [new_content_elements]


func get_value():
	if not self.is_inside_tree():
		yield(self, "ready")
	
	var found_kind_type = config_component.get_kind_type(model.fqn)
	match found_kind_type:
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
	$HeaderBG/Header/Top/ButtonAddValue.visible = is_null
	if not required:
		$HeaderBG/Header/Top/ButtonSetToNull.visible = !is_null


func _on_ButtonSetToNull_pressed() -> void:
	set_to_null(true)


func _on_ButtonAddValue_pressed() -> void:
	set_to_null(false)
	var new_content_elements = config_component.add_element(key, kind, value, self, true)
	if typeof(new_content_elements) == TYPE_ARRAY:
		content_elements = new_content_elements
	else:
		content_elements = [new_content_elements]
	value = get_value()


func _on_key_update(_new_key:String) -> void:
	pass


func _on_Expand_toggled(button_pressed) -> void:
	expand(button_pressed)


func _on_Header_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_Expand_toggled(!$HeaderBG/Header/Top/Expand.pressed)
