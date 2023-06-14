extends WizardStep

const IconButton = preload("res://components/elements/styled/icon_button.tscn")

var highlight_ids:= []

# Question Step
onready var answers = $VBox/AnswerMargin/Answers


func _ready():
	$VBox/TextLabel.connect("meta_hover_started", self, "_on_TextLabel_meta_hover_started")
	$VBox/TextLabel.connect("meta_hover_ended", self, "_on_TextLabel_meta_hover_ended")
	$VBox/TextLabel.connect("meta_clicked", self, "_on_TextLabel_meta_clicked")


func start(_data:Dictionary):
	if not _data["previous_allowed"]:
		emit_signal("can_previous", false)
	var text_label = $VBox/TextLabel
	text_label.percent_visible = 0
	for c in answers.get_children():
		c.queue_free()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if _data["highlight_ids"] != "":
		highlight_ids = str2var(_data["highlight_ids"])
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	var duration = float(text_label.text.length()) / wizard.text_scroll_speed
	$TextAppearTween.remove_all()
	$TextAppearTween.interpolate_property(text_label, "percent_visible", 0, 1, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
	$TextAppearTween.interpolate_callback(self, duration+0.1, "show_answers")
	$TextAppearTween.start()
	wizard.character.state = wizard.character.States.TALK
	answers.hide()
	if answers.get_child_count() == 0 and wizard.data.connections_from.has(step_id):
		create_answers(wizard.data.connections_from[step_id])


func get_answer_buttons():
	var buttons:= []
	for c in $VBox/AnswerMargin/Answers.get_children():
		buttons.append(c.get_node("Btn"))
	return buttons


static func sort_prio(a, b):
	return a.custom_order > b.custom_order


func create_answers(_answers:Array):
	var answer_data:= []
	for answer_id in _answers:
		answer_data.append(wizard.get_step_data(answer_id.to))
	answer_data.sort_custom(self, "sort_prio")
	
	for answer in answer_data:
		if highlight_ids.has(int(answer.custom_order)):
			var spacer := Control.new()
			spacer.rect_min_size.y = 20
			answers.add_child(spacer)
		var answer_wrapper:MarginContainer = MarginContainer.new()
		answer_wrapper.size_flags_horizontal = SIZE_EXPAND_FILL
		var new_answer:Button = Button.new()
		new_answer.name = "Btn"
		new_answer.size_flags_horizontal = SIZE_EXPAND_FILL
		new_answer.align = Button.ALIGN_LEFT
		new_answer.text = answer.step_text
		if answer.icon_path != "":
			answers.columns = 2
			new_answer.icon = load(answer.icon_path)
			new_answer.icon_align = Button.ALIGN_CENTER
			answer_wrapper.size_flags_vertical = SIZE_EXPAND_FILL
		new_answer.focus_mode = Control.FOCUS_ALL
		new_answer.theme_type_variation = "ButtonFocusBorder"
		new_answer.rect_min_size.y = 40
		
		answer_wrapper.add_child(new_answer)
		# Do variable check:
		var var_check : String = answer.variable_check
		if var_check != "":
			if "==" in var_check:
				var var_arr : Array = var_check.split("==")
				if wizard.step_variables.has(var_arr[0]) and wizard.step_variables[var_arr[0]] == var_arr[1]:
					var check_icon := TextureRect.new()
					check_icon.texture = load("res://assets/icons/icon_128_config_set.svg")
					check_icon.expand = true
					check_icon.rect_min_size = Vector2(48, 48)
					check_icon.modulate = Color(0.2, 0.9, 0.3)
					check_icon.size_flags_vertical = SIZE_SHRINK_END
					check_icon.size_flags_horizontal = SIZE_SHRINK_END
					answer_wrapper.add_child(check_icon)
					new_answer.hint_tooltip = "Already configured!"
					new_answer.modulate = Color(0.9,1.0,0.9)
		
		
		if answer.docs_link != "":
			var new_answer_help:Button = IconButton.instance()
			answer_wrapper.add_child(new_answer_help)
			new_answer_help.connect("mouse_entered", self, "_on_TextLabel_meta_hover_started", [answer.docs_link])
			new_answer_help.connect("mouse_exited", self, "_on_TextLabel_meta_hover_ended", [answer.docs_link])
			
			if answer.docs_link.begins_with("http"):
				new_answer_help.icon_tex = load("res://assets/icons/icon_128_help_external_link.svg")
				new_answer_help.connect("pressed", self, "_on_TextLabel_meta_clicked", [answer.docs_link])
			else:
				new_answer_help.icon_tex = load("res://assets/icons/icon_128_questionmark.svg")
			
		answers.add_child(answer_wrapper)
		new_answer.connect("pressed", self, "_on_answer", [str(answer.id)])


func _on_answer(_answer_id:String):
	wizard.last_step = step_id
	wizard.show_step( wizard.data.connections_from[_answer_id][0].to )


func _on_TextAppearTween_tween_all_completed():
	pass


func _on_TextAppearTween_tween_completed(_object, key):
	if key == ":percent_visible":
		wizard.character.state = wizard.character.States.IDLE


func show_answers():
	answers.show()
	var delay:= 0.0
	for a in answers.get_children():
		a.modulate.a = 0
		$TextAppearTween.interpolate_property(a, "modulate:a", 0, 1, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
		if a.get_node("Btn").icon == null:
			$TextAppearTween.interpolate_property(a, "rect_position:x", -10, 0, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
		if delay == 0.0:
			$TextAppearTween. interpolate_callback(a.get_node("Btn"), 0.2, "grab_focus")
		delay += 0.05
	$TextAppearTween.start()


func _on_answer_help(_link:String):
	OS.shell_open(_link)
