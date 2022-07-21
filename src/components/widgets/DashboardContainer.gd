extends Control

onready var date_button := $VBoxContainer/PanelContainer/HBoxContainer/DateButton
onready var dashboard := $VBoxContainer/ScrollContainer/Dashboard
onready var add_widget_popup := $WindowDialog
onready var range_selector := $DateRangeSelector
onready var refresh_option := $VBoxContainer/PanelContainer/HBoxContainer/RefreshOptionButton

func _ready() -> void:
	add_widget_popup.from_date = $DateRangeSelector.from.unix_time
	add_widget_popup.to_date = $DateRangeSelector.to.unix_time
	add_widget_popup.interval = 864 # 100 points in a day
	dashboard.ts_start = $DateRangeSelector.from.unix_time
	dashboard.ts_end = $DateRangeSelector.to.unix_time
	dashboard.step = 864
	

func _on_AddWidgetButton_pressed() -> void:
	$WindowDialog.popup_centered()
	
func _on_WidgetContainer_config_pressed(widget_container) -> void:
	$WindowDialog.edit_widget(widget_container)


func _on_DateButton_pressed() -> void:
	$DateRangeSelector.rect_position = dashboard.rect_position
	$DateRangeSelector.rect_position.x = rect_size.x / 2 - $DateRangeSelector.rect_size.x / 26
	
	$DateRangeSelector.popup()


func _on_DateRangeSelector_range_selected(start : int, end : int, text : String) -> void:
	date_button.text = text
	add_widget_popup.from_date = start
	add_widget_popup.to_date = end
	add_widget_popup.interval = (end-start)/100
	print("refresh: ", end-start)
	dashboard.refresh(start, end, (end-start)/100)


func _on_LockButton_toggled(button_pressed : bool) -> void:
	$VBoxContainer/PanelContainer/HBoxContainer/AddWidgetButton.visible = !button_pressed


func _on_Timer_timeout() -> void:
	range_selector._on_AcceptButton_pressed()
	

func _on_OptionButton_item_selected(_index : int) -> void:
	var text : String = refresh_option.text
	text = text.replace("min", "*60")
	text = text.replace("hr", "*3600")
	var expression = Expression.new()
	expression.parse(text)
	$Timer.wait_time = expression.execute()
