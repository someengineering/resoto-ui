extends Control

onready var date_button := $VBoxContainer/PanelContainer/HBoxContainer/DateButton
onready var dashboard := $VBoxContainer/Dashboard
onready var add_widget_popup := $WindowDialog

func _ready():
	add_widget_popup.from_date = $DateRangeSelector.from.unix_time
	add_widget_popup.to_date = $DateRangeSelector.to.unix_time

func _on_AddWidgetButton_pressed():
	$WindowDialog.popup_centered()


func _on_DateButton_pressed():
	$DateRangeSelector.rect_position = $VBoxContainer/Dashboard.rect_position
	$DateRangeSelector.rect_position.x = rect_size.x / 2 - $DateRangeSelector.rect_size.x / 26
	
	$DateRangeSelector.popup()


func _on_DateRangeSelector_range_selected(start, end, text):
	date_button.text = text
	add_widget_popup.from_date = start
	add_widget_popup.to_date = end
	dashboard.refresh(start, end)
	

func _on_LockButton_toggled(button_pressed):
	$VBoxContainer/PanelContainer/HBoxContainer/AddWidgetButton.visible = !button_pressed
