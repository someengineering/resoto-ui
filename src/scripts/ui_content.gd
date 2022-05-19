extends CanvasLayer

var config_active:bool = false

func show_config(show:bool):
	$Content.visible = !show
	$Config.visible = show


func _on_ButtonConfig_pressed():
	config_active = !config_active
	show_config(config_active)


func _on_Config_CloseConfig():
	config_active = false
	show_config(false)
