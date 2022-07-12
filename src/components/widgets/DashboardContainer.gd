extends Control

onready var date_button := $VBoxContainer/PanelContainer/HBoxContainer/DateButton
onready var dashboard := $VBoxContainer/Dashboard
func _on_AddWidgetButton_pressed():
	$WindowDialog.popup_centered()


func _on_DateButton_pressed():
	$DateRangeSelector.rect_position = $VBoxContainer/Dashboard.rect_position
	$DateRangeSelector.rect_position.x = rect_size.x / 2 - $DateRangeSelector.rect_size.x / 26
	
	$DateRangeSelector.popup()


func _on_DateRangeSelector_range_selected(start, end, text):
	date_button.text = text
	dashboard.refresh(start, end)
	
	
