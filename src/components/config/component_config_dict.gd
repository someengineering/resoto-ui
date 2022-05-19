extends HBoxContainer

var value_field = null
var key:String setget set_key
var kind:String = "" setget set_kind
var value setget set_value, get_value

onready var key_label = $Key

func set_key(_value:String):
	key = _value
	key_label.text = key


func set_kind(_kind:String):
	kind = _kind
	match kind:
		"null":
			return
		"string":
			value_field = $VarValueString
		"int64":
			value_field = $VarValueInt
	value_field.show()


func set_value(_value):
	value = _value
	match kind:
		"null":
			return
		"string":
			if value == null:
				value = ""
			value_field.text = str(value)
		"int64":
			value_field.value = int(value)


func get_value():
	return value
