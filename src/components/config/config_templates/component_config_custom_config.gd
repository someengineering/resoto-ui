extends VBoxContainer

var value setget set_value, get_value
var value_creation_error:bool = false
var key:String = ""

onready var config_value_text : TextEdit = $CustomConfigValue


func set_value(_new_value):
	value = _new_value
	config_value_text.text = JSON.print(value, "  ")


func get_value():
	value_creation_error = false
	$CustomConfigValue/ErrorOutline.hide()
	var text = config_value_text.text
	var json_parse_result:JSONParseResult = JSON.parse(text)
	if json_parse_result.error == OK:
		return json_parse_result.result
	else:
		value_creation_error = true
		$CustomConfigValue/ErrorOutline.show()
		if not config_value_text.is_connected("text_changed", self, "_on_text_changed"):
			config_value_text.connect("text_changed", self, "_on_text_changed")
		config_value_text.cursor_set_line(json_parse_result.error_line)
		var error_message = "Key: '" + key + "'\nLine: " + str(json_parse_result.error_line + 1) + "\nError: " + json_parse_result.error_string
		_g.emit_signal("add_toast", "JSON error.", error_message, 1, self, 4)
		# this is done to actively create an error when trying to save the config.
		return "\\\\\\\\"


func _on_text_changed():
	if value_creation_error:
		$CheckParseTimer.start()
	else:
		$CheckParseTimer.stop()
		config_value_text.disconnect("text_changed", self, "_on_text_changed")


func _on_CheckParseTimer_timeout():
	get_value()
