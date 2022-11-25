extends ToolButton

func _ready():
	_g.connect("setup_wizard_minimized", self, "_on_setup_wizard_minimized")
	_g.connect("collect_run_finished", self, "_on_collect_run_finished")


func _on_setup_wizard_minimized(_during_collect:=false):
	show()
	if _during_collect:
		$Progressing.show()
	else:
		$Progressing.hide()
	$Done.hide()


func _on_collect_run_finished():
	if is_visible_in_tree():
		$Done.show()
		$Progressing.hide()
		


func _on_WizardButton_pressed():
	_g.emit_signal("nav_change_section", "setup_wizard")
	hide()
