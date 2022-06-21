extends PanelContainer


func _on_Button_toggled(button_pressed):
	$VBoxContainer/DatasourceSettings.visible = not button_pressed
