extends WizardStep

func start(_data):
	wizard.change_section(_data.section_goto)
