class_name DashboardContainer
extends Control

signal deleted
signal dashboard_changed(dashboard)
signal dashboard_closed(dashboard)

var dashboard_name : String = "" setget set_dashboard_name
var last_saved_name : String = ""
var uuid : String = ""

onready var last_refresh := Time.get_unix_time_from_system()
var refresh_time := 900

# just for load
var refresh_time_option : String setget set_refresh_time_option
var time_range : String setget set_range
var force_refresh := false
var widgets : Array setget set_widgets
var cloud : String setget set_cloud
var account : String setget set_account
var region : String setget set_region

var initial_load : bool = true

onready var date_button := $VBoxContainer/PanelContainer/DateButton
onready var dashboard := $VBoxContainer/ScrollContainer/Dashboard
onready var add_widget_popup := $WindowDialog
onready var range_selector := $DateRangeSelector
onready var refresh_option := $VBoxContainer/PanelContainer/HBoxContainer/RefreshOptionButton
onready var name_label := $VBoxContainer/PanelContainer/HBoxContainer/DashboardNameLabel
onready var lock_button := $VBoxContainer/PanelContainer/HBoxContainer/LockButton

onready var clouds_combo := $VBoxContainer/FiltersContainer/CloudsCombo
onready var accounts_combo := $VBoxContainer/FiltersContainer/AccountsCombo
onready var regions_combo := $VBoxContainer/FiltersContainer/RegionsCombo


func _ready() -> void:
	add_widget_popup.from_date = $DateRangeSelector.from.unix_time
	add_widget_popup.to_date = $DateRangeSelector.to.unix_time
	add_widget_popup.interval = 144 # 500 points in a day
	dashboard.ts_start = $DateRangeSelector.from.unix_time
	dashboard.ts_end = $DateRangeSelector.to.unix_time
	dashboard.step = 144
	
	self.dashboard_name = name
	
	if InfrastructureInformation.infra_info != []:
		_on_infra_info_updated()
	InfrastructureInformation.connect("infra_info_updated", self, "_on_infra_info_updated")
	
	dashboard.lock(true)


func _process(_delta : float) -> void:
	var current_time := Time.get_unix_time_from_system()
	if current_time - last_refresh > refresh_time or force_refresh:
		print("refresh: %s" % Time.get_datetime_string_from_system(false,true))
		force_refresh = false
		last_refresh = current_time
		dashboard.refresh()


func _on_AddWidgetButton_pressed() -> void:
	$WindowDialog.popup_centered()


func _on_WidgetContainer_config_pressed(widget_container) -> void:
	$WindowDialog.edit_widget(widget_container)


func _on_DateButton_pressed() -> void:
	$DateRangeSelector.rect_global_position.y = date_button.rect_global_position.y + date_button.rect_size.y
	$DateRangeSelector.rect_position.x = rect_size.x / 2 - $DateRangeSelector.rect_size.x / 2
	$DateRangeSelector.popup()


func _on_DateRangeSelector_range_selected(start : int, end : int, text : String) -> void:
	date_button.text = text
	add_widget_popup.from_date = start
	add_widget_popup.to_date = end
	add_widget_popup.interval = (end-start)/500
	dashboard.ts_end = end
	dashboard.ts_start = start
	dashboard.step = (end-start)/500
	force_refresh = true
	if initial_load:
		emit_signal("dashboard_changed", self)


func _on_LockButton_toggled(button_pressed : bool) -> void:
	$VBoxContainer/PanelContainer/HBoxContainer/AddWidgetButton.visible = button_pressed
	dashboard.lock(!button_pressed)
	if !button_pressed:
		emit_signal("dashboard_changed", self)


func _on_OptionButton_item_selected(_index : int) -> void:
	var text : String = refresh_option.text
	text = text.replace("min", "*60")
	text = text.replace("hr", "*3600")
	var expression = Expression.new()
	expression.parse(text)
	refresh_time = expression.execute()


func _on_DeleteButton_pressed() -> void:
	emit_signal("deleted", get_position_in_parent())
	queue_free()


func set_dashboard_name(new_name : String) -> void:
	name = new_name
	dashboard_name = new_name
	$VBoxContainer/PanelContainer/HBoxContainer/DashboardNameLabel.text = new_name


func _on_DashboardNameLabel_text_entered(new_text : String) -> void:
	set_dashboard_name(new_text)
	if initial_load:
		emit_signal("dashboard_changed", self)
		
	last_saved_name = new_text


func _on_infra_info_updated() -> void:
	var clouds_filters = ["All"]
	clouds_filters.append_array(InfrastructureInformation.clouds)
	var regions_filters = ["All"]
	for _cloud in InfrastructureInformation.regions:
		regions_filters.append_array(InfrastructureInformation.regions[_cloud])
	var accounts_filters = ["All"]
	for _cloud in InfrastructureInformation.accounts:
		accounts_filters.append_array(InfrastructureInformation.accounts[_cloud])
		
	clouds_combo.set_items(clouds_filters)
	regions_combo.set_items(regions_filters)
	accounts_combo.set_items(accounts_filters)


func _on_CloudsCombo_option_changed(option):
	if option == "All" or option == "":
		var regions_filters = ["All"]
		for _cloud in InfrastructureInformation.regions:
			regions_filters.append_array(InfrastructureInformation.regions[_cloud])
		var accounts_filters = ["All"]
		for _cloud in InfrastructureInformation.accounts:
			accounts_filters.append_array(InfrastructureInformation.accounts[_cloud])
			
		regions_combo.set_items(regions_filters)
		accounts_combo.set_items(accounts_filters)
		
		dashboard.filters["cloud"] = ""
		cloud = ""
	else:
		accounts_combo.clear()
		if option in InfrastructureInformation.accounts:
			var acc : Array = InfrastructureInformation.accounts[option].duplicate()
			acc.push_front("All")
			accounts_combo.set_items(acc)
			
		regions_combo.clear()
		if option in InfrastructureInformation.regions:
			var reg : Array = InfrastructureInformation.regions[option].duplicate()
			reg.push_front("All")
			regions_combo.set_items(reg)
			
		dashboard.filters["cloud"] = option
		cloud = option
		
	dashboard.filters["region"] = ""
	region = ""
	dashboard.filters["account"] = ""
	account = ""
	add_widget_popup.dashboard_filters = dashboard.filters
	force_refresh = true
	
	if initial_load:
		emit_signal("dashboard_changed", self)


func _on_AccountsCombo_option_changed(option):
	if option == "All": option = ""
	dashboard.filters["account"] = option
	account = option
	add_widget_popup.dashboard_filters["account"] = option
	force_refresh = true
	
	if initial_load:
		emit_signal("dashboard_changed", self)


func _on_RegionsCombo_option_changed(option):
	if option == "All": option = ""
	dashboard.filters["region"] = option
	region = option
	add_widget_popup.dashboard_filters["region"] = option
	force_refresh = true
	
	if initial_load:
		emit_signal("dashboard_changed", self)


func get_data() -> Dictionary:
	var _widgets : Array = []
	for widget in dashboard.widgets.get_children():
		_widgets.append(widget.get_data())
	
	var data = {
		"dashboard_name" : dashboard_name,
		"refresh_time_option" : refresh_option.selected,
		"time_range" : date_button.text,
		"cloud" : cloud,
		"account" : account,
		"region" : region,
		"widgets" : _widgets,
		"uuid" : uuid
	}
	
	return data


func set_refresh_time_option(option : String) -> void:
	for i in refresh_option.get_item_count():
		if refresh_option.get_item_text(i) == option:
			refresh_option.select(i)
			break


func set_range(new_range : String) -> void:
	var range_text = new_range
	new_range = new_range.to_lower()
	if "last" in new_range:
		new_range = new_range.replace("last", "now - ")
		new_range += " to now"
		
	var range_parts := new_range.split(" to ")
	range_selector.from.process_date(range_parts[0], false)
	range_selector.to.process_date(range_parts[1], false)
	dashboard.ts_start = range_selector.from.unix_time
	dashboard.ts_end = range_selector.to.unix_time
	range_selector._on_AcceptButton_pressed()
	date_button.text = range_text


func set_cloud(new_cloud : String):
	cloud = new_cloud
	clouds_combo.text = cloud


func set_account(new_account : String):
	account = new_account
	accounts_combo.text = account


func set_region(new_region : String):
	region = new_region
	regions_combo.text = region


func set_widgets(new_widgets : Array) -> void:
	for settings in new_widgets:
		var widget_data = settings["widget_data"]
		widget_data["data_sources"] = settings["data_sources_data"]
		var container : WidgetContainer = yield(dashboard.add_widget(widget_data), "completed")
		container.position_on_grid.x = settings["position:x"]
		container.position_on_grid.y = settings["position:y"]
		container.size_on_grid.x = settings["size:x"]
		container.size_on_grid.y = settings["size:y"]
		container.rect_position = Vector2(settings["position:x"], settings["position:y"]) * container.grid_size
		container.rect_size = Vector2(settings["size:x"], settings["size:y"]) * container.grid_size
		container.parent_reference.rect_size = container.rect_size
		container.parent_reference.rect_position = container.rect_position
		container.set_anchors()


func _on_WindowDialog_widget_added(_widget_data):
	force_refresh = true


func _on_ExportButton_pressed():
	if OS.has_feature("HTML5"):
		JavaScript.download_buffer(JSON.print(get_data(),"\t").to_utf8(), "%s.json" % dashboard_name)


func _on_CloseButton_pressed():
	emit_signal("dashboard_closed", self)
