extends CanvasLayer

var config_active:bool = false

func show_config(show:bool):
	if show:
		$Config.load_config()
	$Content.visible = !show
	$Config.visible = show


func _on_ButtonConfig_pressed():
	config_active = !config_active
	show_config(config_active)


func _on_Config_close_config():
	config_active = false
	show_config(false)


func _on_TerminalsButton_toggled(button_pressed):
	$Content/TerminalManager.show()
	$Content/DashBoardManager.hide()


func _on_DashboardsButton_toggled(button_pressed):
	$Content/TerminalManager.hide()
	$Content/DashBoardManager.show()
