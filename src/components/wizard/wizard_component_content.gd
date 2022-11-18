extends ComponentContainer


func _on_WizardComponent_visibility_changed():
	if visible and $Wizard.current_step == null:
		$Wizard.load_wizard_graph("setup_wizard")
