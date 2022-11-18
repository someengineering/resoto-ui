extends WizardStep

func start(_data):
	emit_signal("update_section_title", _data.section_display_title)
	emit_signal("next")
