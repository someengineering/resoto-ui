extends Control
class_name ConfigComponentEnum

signal value_field_selected

var value_field = null
var kind:String = "" setget set_kind
var value setget set_value, get_value
var description:String = "" setget set_description
var key:String = "" setget set_key
var enum_values:Array = [] setget set_enum_values
var required:bool = false setget set_required
var is_null:bool = false
var descriptions_as_hints:bool = true

onready var enum_button:OptionButton = $VarContent/VarValueEnum
onready var null_value = $VarContent/VarValueIsNull


func _ready():
	if descriptions_as_hints:
		$Description.hide()


func set_required(_value:bool) -> void:
	required = _value
	if required:
		$VarContent/ButtonAddValue.hide()
		$VarContent/ButtonSetToNull.hide()
		return
	
	set_to_null(value==null)


func set_kind(_kind:String) -> void:
	kind = _kind


func set_enum_values(_enum_values:Array) -> void:
	enum_values = _enum_values
	if not self.is_inside_tree():
		yield(self, "ready")
	enum_button.clear()
	for ev in enum_values:
		enum_button.add_item(ev)


func _on_VarValueEnum_item_selected(index:int) -> void:
	value = enum_button.get_item_text(index)


func set_value(_value) -> void:
	value = _value
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if value == null:
		set_to_null(true)
		return


func get_value():
	if is_null:
		return null
	return value


func _make_custom_tooltip(for_text):
	var tooltip = preload("res://components/shared/custom_bb_hint_tooltip.tscn").instance()
	tooltip.get_node("Text").bbcode_text = for_text
	return tooltip


func set_description(_value:String) -> void:
	description = _value
	if descriptions_as_hints:
		hint_tooltip = "[b]Property:[/b]\n[code]%s[/code]\n\n%s" % [key, description]
		return
	if _value == "":
		$Description.hide()
	$Description.text = _value


func set_key(_value:String) -> void:
	key = _value
	if _value == "":
		$VarContent/VarName.hide()
	$VarContent/VarName.text = key.capitalize()


func _on_ButtonSetToNull_pressed() -> void:
	set_to_null(true)


func set_to_null(to_null:bool) -> void:
	is_null = to_null
	
	if not self.is_inside_tree():
		yield(self, "ready")
	
	enum_button.visible = !is_null
	null_value.visible = is_null
	
	if not required:
		$VarContent/ButtonAddValue.visible = is_null
		$VarContent/ButtonSetToNull.visible = !is_null


func set_default(_default:bool) -> void:
	if _default:
		_on_ButtonAddValue_pressed()


func _on_ButtonAddValue_pressed() -> void:
	set_to_null(false)
	value = enum_button.get_item_text(0)
