extends WizardStep


func _ready():
	Style.add_self($VBox/TextLabel, Style.c.LIGHT)
	$VBox/TextLabel.connect("meta_hover_started", self, "_on_TextLabel_meta_hover_started")
	$VBox/TextLabel.connect("meta_hover_ended", self, "_on_TextLabel_meta_hover_ended")
	$VBox/TextLabel.connect("meta_clicked", self, "_on_TextLabel_meta_clicked")


func start(_data:Dictionary):
	if not _data["previous_allowed"]:
		emit_signal("can_previous", false)
	var text_label = $VBox/TextLabel
	text_label.percent_visible = 0
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	var duration = float(text_label.text.length()) / wizard.text_scroll_speed
	$TextAppearTween.remove_all()
	$TextAppearTween.interpolate_property(text_label, "percent_visible", 0, 1, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
	wizard.character.state = wizard.character.States.TALK
	$TextAppearTween.start()


func _on_TextAppearTween_tween_all_completed():
	emit_signal("can_continue")


func _on_TextAppearTween_tween_completed(_object, key):
	if key == ":percent_visible":
		wizard.character.state = wizard.character.States.IDLE
