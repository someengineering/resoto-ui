extends Control
class_name ConfigComponentSimple

signal value_field_selected

var value_field = null
var kind:String = "" setget set_kind
var value setget set_value, get_value
var description:String = "" setget set_description
var key:String = "" setget set_key
var required:bool = false setget set_required
var descriptions_as_hints:bool = true

onready var null_value = $VarContent/VarValueIsNull


func _ready():
	if descriptions_as_hints:
		$Description.hide()


func set_default(_value:bool) -> void:
	if not _value:
		return
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			set_value("")
		"int64", "int32":
			set_value(0)
		"float", "double":
			set_value(0.0)
		"boolean":
			set_value(false)


func set_required(_value:bool) -> void:
	required = _value
	if required:
		$VarContent/ButtonAddValue.hide()
		$VarContent/ButtonSetToNull.hide()
		return
	
	set_to_null(value==null)


func set_kind(_kind:String) -> void:
	kind = _kind
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			value_field = $VarContent/VarValueTextbox
		"int64", "int32":
			value_field = $VarContent/VarValueInt
		"float", "double":
			value_field = $VarContent/VarValueFloat
		"boolean":
			value_field = $VarContent/VarValueBool
	value_field.show()
	emit_signal("value_field_selected")


func set_value(_value) -> void:
	value = _value
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if value == null:
		set_to_null(true)
		return
	
	match kind:
		"null":
			return
		"string", "date", "datetime", "duration", "trafo.duration_to_datetime":
			value_field.text = str(value)
		"int64", "int32", "float", "double":
			var new_value = str(value)
			value_field.set_number(new_value)
		"boolean":
			value_field.pressed = bool(value)
		"any":
			value_field.text = JSON.print(value)


func get_value():
	if value == null:
		return null
	match kind:
		"string", "date", "datetime", "duration", "trafo.duration_to_datetime":
			return value_field.text
		"int64", "int32":
			return int(value_field.text)
		"float", "double":
			return float(value_field.text)
		"boolean":
			return bool(value_field.pressed)
		"any":
			var json_parse_result:JSONParseResult = JSON.parse(value_field.text)
			if json_parse_result.error == OK:
				return json_parse_result.result
			else:
				return str(value_field.text)


func _make_custom_tooltip(for_text):
	var tooltip = preload("res://ui/elements/BBTooltip.tscn").instance()
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
	if to_null:
		value = null
	
	if not value_field:
		yield(self, "value_field_selected")
	if not self.is_inside_tree():
		yield(self, "ready")
	
	value_field.visible = !to_null
	null_value.visible = to_null
	
	if not required:
		$VarContent/ButtonAddValue.visible = to_null
		$VarContent/ButtonSetToNull.visible = !to_null


func _on_key_update(_new_key:String) -> void:
	set_key(_new_key)


func _on_ButtonAddValue_pressed() -> void:
	var new_value = null
	set_to_null(false)
	
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			new_value = ""
		"int64", "int32":
			new_value = 0.0
		"float", "double":
			new_value = 0
		"boolean":
			new_value = false
	set_value(new_value)
