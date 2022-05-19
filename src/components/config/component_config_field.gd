extends VBoxContainer

var value_field = null
var kind = "" setget set_kind
var value setget set_value, get_value
var description = "" setget set_description
var var_name = "" setget set_var_name
var required:bool = false

func set_kind(_kind:String):
	kind = _kind
	match kind:
		"null":
			return
		"string":
			value_field = $VarContent/VarValueString
		"int64":
			value_field = $VarContent/VarValueInt
		"boolean":
			value_field = $VarContent/VarValueBool
	value_field.show()


func set_value(_value):
	value = _value
	match kind:
		"null":
			return
		"string":
			value_field.text = str(value) if value != null else ""
		"int64":
			var new_value = str(value) if value != null else ""
			value_field.set_number(new_value)
		"boolean":
			value_field.pressed = bool(value)


func get_value():
	match kind:
		"string":
			return str(value_field.text) if value_field.text != "" else null
		"int64":
			return str(value_field.text) if value_field.text != "" else null
		"boolean":
			return bool(value_field.pressed)


func set_description(_value:String):
	description = _value
	if _value == "":
		$Description.hide()
	$Description.text = _value


func set_var_name(_value:String):
	var_name = _value
	$VarContent/VarName.text = _value.capitalize()
