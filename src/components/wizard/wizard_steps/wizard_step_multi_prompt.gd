extends WizardStep

var mandatory_prompts := []
var optional_prompts := []


func _ready():
	do_intercept_next = true

func start(_data:Dictionary):
	if not _data["previous_allowed"]:
		emit_signal("can_previous", false)
	if intercept_next:
		do_intercept_next = true
	var text_label = $VBox/TextLabel
	text_label.percent_visible = 0
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	
	var duration = float(text_label.text.length()) / wizard.text_scroll_speed
	$TextAppearTween.remove_all()
	$TextAppearTween.interpolate_property(text_label, "percent_visible", 0, 1, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
	$TextAppearTween.start()
	wizard.character.state = wizard.character.States.TALK
	
	create_fields(wizard.data.connections_from[step_id])
	
	mandatory_prompt_text_changed("")
	

func _on_TextAppearTween_tween_completed(_object, key):
	if key == ":percent_visible":
		wizard.character.state = wizard.character.States.IDLE


func create_fields(_prompts : Array):
	for field in $VBox/FieldsMargin/Fields.get_children():
		$VBox/FieldsMargin/Fields.remove_child(field)
		field.queue_free()
		
	mandatory_prompts = []
	optional_prompts = []
	
	for prompt in _prompts:
		if prompt.from_port == 0:
			continue
		var prompt_field := $FieldTemplate.duplicate()
		
		var prompt_data = wizard.get_step_data(prompt.to)
		prompt_field.get_node("LineEdit").visible = not prompt_data.expand_field
		prompt_field.get_node("TextEdit").visible = prompt_data.expand_field
#		prompt_field.get_node("CheckBox").visible = prompt_data.expand_field
		prompt_field.get_node("CheckBox").connect("pressed", self, "change_textbox_enabled", [prompt_field.get_node("TextEdit"), prompt_field.get_node("CheckBox")])
		if prompt_field.get_node("TextEdit").visible: 
			prompt_field.size_flags_vertical = SIZE_EXPAND_FILL
		
		prompt_data["field"] = prompt_field
		if prompt_data.docs_link != "":
			prompt_field.get_node("DocButton").show()
			prompt_field.get_node("DocButton").url = prompt_data.docs_link
		
		prompt_field.get_node("Label").text = prompt_data.step_text
		
		mandatory_prompts.append(prompt_data)
		prompt_field.get_node("LineEdit").connect("text_changed", self, "mandatory_prompt_text_changed")
		prompt_field.get_node("TextEdit").connect("text_changed", self, "mandatory_prompt_text_changed")
		
			
		$VBox/FieldsMargin/Fields.add_child(prompt_field)
		prompt_field.show()

func mandatory_prompt_text_changed(_new_text : String = ""):
	
	var all_filled := true
	for prompt in mandatory_prompts:
		if get_text_node(prompt).text == "":
			all_filled = false
			break
			
	emit_signal("can_continue", all_filled)


func consume_next():
	var prompts := []
	prompts.append_array(optional_prompts)
	prompts.append_array(mandatory_prompts)
	
	for prompt in prompts:
		var text_node = get_text_node(prompt)
		if text_node.text == "":
			continue
		config_key = prompt.config_key
		config_value_path = prompt.value_path
		
		var value : String = text_node.text
		
		if prompt.format != "" and "{{value}}" in prompt.format:
			value = prompt.format.replace("{{value}}", value)
		
		update_config_string_separator(value, prompt.separator)
		
	emit_signal("next")


func get_text_node(prompt):
	return prompt.field.get_node("LineEdit") if prompt.field.get_node("LineEdit").visible else prompt.field.get_node("TextEdit")


func change_textbox_enabled(text_box : TextEdit, checkbox : CheckBox):
	text_box.visible = checkbox.pressed
