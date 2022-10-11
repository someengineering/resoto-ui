extends VBoxContainer

const TEXTXMARGIN = 132

var value setget set_value, get_value
var value_creation_error:bool = false
var key:String = ""

onready var config_value_text = $CustomConfigValue



func set_value(_new_value):
	value = _new_value
	config_value_text.text = JSON.print(value, "  ")


func get_value():
	value_creation_error = false
	var text = config_value_text.text
	var json_parse_result:JSONParseResult = JSON.parse(text)
	if json_parse_result.error == OK:
		return json_parse_result.result
	else:
		value_creation_error = true
		var error_message = "Key: '" + key + "'\nLine: " + str(json_parse_result.error_line + 1) + "\nError: " + json_parse_result.error_string
		_g.emit_signal("add_toast", "JSON error.", error_message, 1, self)
		return value
