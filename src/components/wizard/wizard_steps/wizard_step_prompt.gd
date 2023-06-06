extends WizardStep

# Prompt Step
var value:= ""
var value_path:= ""
var separator:= ""
var format := ""
var expand_field : bool = false
var regex:RegEx = RegEx.new()
var placeholder_scene:Node = null

onready var margin = $VBox/LineEditMargin

func _enter_tree():
	regex.compile("\\[(.*?)\\]")


func start(_data:Dictionary):
	if not _data["previous_allowed"]:
		emit_signal("can_previous", false)
	if intercept_next:
		do_intercept_next = true
	var text_label = $VBox/TextLabel
	config_key = _data.config_key
	value_path = _data.value_path
	config_action = _data.action
	separator = _data.separator
	format = _data.format
	expand_field = _data.expand_field
	$VBox/LineEditMargin/LineEdit.text = ""
	$VBox/LineEditMargin/TextEdit.text = ""
	text_label.percent_visible = 0
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	var duration = float(text_label.text.length()) / wizard.text_scroll_speed
	$TextAppearTween.remove_all()
	$TextAppearTween.interpolate_property(text_label, "percent_visible", 0, 1, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
	$TextAppearTween.start()
	wizard.character.state = wizard.character.States.TALK
	$VBox/LineEditMargin/LineEdit.hide()
	$VBox/LineEditMargin/TextEdit.hide()
	_on_WizardStep_StepPrompt_resized()


func _on_LineEdit_text_changed(new_text):
	value = new_text


func _on_TextAppearTween_tween_completed(_object, key):
	if key == ":percent_visible":
		wizard.character.state = wizard.character.States.IDLE


func _on_TextAppearTween_tween_all_completed():
	if not expand_field:
		$VBox/LineEditMargin/LineEdit.show()
		$VBox/LineEditMargin/LineEdit.grab_focus()
	else:
		$VBox/LineEditMargin/TextEdit.show()
		$VBox/LineEditMargin/TextEdit.grab_focus()
	
	emit_signal("can_continue")


func consume_next():
	if placeholder_scene != null:
		placeholder_scene.consume_next()
		return
	
	do_intercept_next = false
	var final_value_path = value_path
	if value_path.find("%VALUE%"):
		final_value_path = value_path.replace("%VALUE%", value)
	
	var save_in_json_object:RegExMatch = regex.search(final_value_path)
	if save_in_json_object != null:
		final_value_path = final_value_path.trim_prefix(save_in_json_object.strings[0]).trim_prefix(".")
	
	config_value_path = final_value_path
	
	if format != "" and "{{value}}" in format:
		value = format.replace("{{value}}", value)
	
	if save_in_json_object != null:
		wizard.new_json_objects[save_in_json_object.strings[1]][final_value_path] = value
	else:
		update_config_string_separator(value, separator)
	
	emit_signal("next")


func _on_LineEdit_text_entered(_new_text):
	consume_next()


func forward_can_continue():
	emit_signal("can_continue")

func forward_can_previous(_can:bool):
	emit_signal("can_previous", _can)

func forward_next(_step_id:=0):
	emit_signal("next", _step_id)


func _on_WizardStep_StepPrompt_resized():
	if not margin:
		return
	var total_size = margin.rect_size.x
	var margin_x = clamp((total_size/4)-140, 0, 200)
	margin.add_constant_override("margin_left", margin_x)
	margin.add_constant_override("margin_right", margin_x)


func _on_TextEdit_text_changed():
	value = $VBox/LineEditMargin/TextEdit.text
