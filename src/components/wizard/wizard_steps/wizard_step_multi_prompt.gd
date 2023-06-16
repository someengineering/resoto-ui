extends WizardStep

var mandatory_prompts := []
var optional_prompts := []

var drop_file_prompt = null

onready var fields := $VBox/FieldsMargin/Fields


func _ready():
	do_intercept_next = true
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	

func _on_files_dropped(files, _screen):
	if !is_visible_in_tree():
		return
	var file = File.new()
	if not file.open(files[0], File.READ):
		
		for field in fields.get_children():
			if field is MultiFieldTemplate:
				fields.remove_child(field)
				field.queue_free()
				
		$VBox/FieldsMargin/Fields/DropFilesLabel.hide()
		var data = file.get_as_text()
		var element = preload("res://components/wizard/multi_field_template_element.tscn").instance()
		
		
		for prompt in mandatory_prompts:
			if prompt.res_name == "StepMultipleFields":
				prompt["field"] = element
		
		fields.add_child(element)
		element.value = data
		
		element.line_edit.hide()
		element.line_edit_label.hide()
		
		var key : String = element.file_name.replace( "."+element.file_name.get_extension(), "")
			
		element.key = key
		
		element.file_name = drop_file_prompt.format.replace("{{key}}", element.file_name)
		

		
		fields.move_child($VBox/FieldsMargin/Fields/DropFilesLabel, fields.get_child_count())

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
	
	if fields.get_child_count() > 1:
		return
		
	mandatory_prompts = []
	optional_prompts = []
	
	for prompt in _prompts:
		if prompt.from_port == 0:
			continue
			
		
		var prompt_data = wizard.get_step_data(prompt.to)
		
		mandatory_prompts.append(prompt_data)
		
		if prompt_data.res_name == "StepMultipleFields":
			
			var paths = prompt_data.value_path.split(".")
	
			var config = wizard.remote_configs[prompt_data.config_key]

			for path in paths:
				config = config[path]
				
			if "~/.aws/credentials" in config and fields.get_child_count() > 1:
				var value = config["~/.aws/credentials"]
				var element = preload("res://components/wizard/multi_field_template_element.tscn").instance()
				fields.add_child(element)

				element.value = value
				element.key = "~/.aws/credentials"
				element.file_name = "~/.aws/credentials"
				prompt_data["field"] = element
			else: 
				$VBox/FieldsMargin/Fields/DropFilesLabel.show()
			
			drop_file_prompt = prompt_data
		else:
			var prompt_field := $FieldTemplate.duplicate()
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
			
			prompt_field.get_node("LineEdit").connect("text_changed", self, "mandatory_prompt_text_changed")
			prompt_field.get_node("TextEdit").connect("text_changed", self, "mandatory_prompt_text_changed")
			
				
			fields.add_child(prompt_field)
			fields.move_child($VBox/FieldsMargin/Fields/DropFilesLabel, fields.get_child_count())
			prompt_field.show()

func mandatory_prompt_text_changed(_new_text : String = ""):
	
	var all_filled := true
	for prompt in mandatory_prompts:
		if prompt.res_name == "StepMultipleFields":
			if not ("field" in prompt and is_instance_valid(prompt["field"])):
				all_filled = false
				break
		else:
			if get_text_node(prompt).text == "":
				all_filled = false
				break
			
	emit_signal("can_continue", all_filled)


func consume_next():
	var prompts := []
	prompts.append_array(optional_prompts)
	prompts.append_array(mandatory_prompts)
	
	for prompt in prompts:
		config_key = prompt.config_key
		config_value_path = prompt.value_path
		
		var value : String
		if prompt.res_name == "StepMultipleFields":
			var key : String = prompt.format.replace("{{key}}",prompt.field.key)
			value = var2str({key : prompt.field.value})
		else:
			var text_node = get_text_node(prompt)
			if text_node.text == "":
				continue
			
			value = text_node.text
			
			if prompt.format != "" and "{{value}}" in prompt.format:
				value = prompt.format.replace("{{value}}", value)
		
		update_config_string_separator(value, prompt.separator if "separator" in prompt else "")
		
	if drop_file_prompt == null:
		var paths = "resotoworker.files_in_home_dir".split(".")
	
		var config = wizard.remote_configs["resoto.worker"]

		for path in paths:
			config = config[path]
			
		if "~/.aws/credentials" in config:
			config.erase("~/.aws/credentials")
			wizard.emit_signal("setup_wizard_changed_config")
		
	emit_signal("next")


func get_text_node(prompt):
	return prompt.field.get_node("LineEdit") if prompt.field.get_node("LineEdit").visible else prompt.field.get_node("TextEdit")


func change_textbox_enabled(text_box : TextEdit, checkbox : CheckBox):
	text_box.visible = checkbox.pressed


func _on_Fields_child_entered_tree(_node):
	mandatory_prompt_text_changed("")


func _on_Fields_child_exiting_tree(_node):
	if _node is MultiFieldTemplate:
		emit_signal("can_continue", false)
		$VBox/FieldsMargin/Fields/DropFilesLabel.show()
		
		var paths = drop_file_prompt.value_path.split(".")
	
		var config = wizard.remote_configs[drop_file_prompt.config_key]

		for path in paths:
			config = config[path]
			
		if "~/.aws/credentials" in config:
			config.erase("~/.aws/credentials")
			wizard.emit_signal("setup_wizard_changed_config")
