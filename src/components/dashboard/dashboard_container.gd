class_name DashboardContainer
extends Control

const min_resolution := 144
const WidgetScenes := {
	"Indicator" : preload("res://components/dashboard/widget_indicator/widget_indicator.tscn"),
	"Chart" : preload("res://components/dashboard/widget_chart/widget_chart.tscn"),
	"Table" : preload("res://components/dashboard/widget_table/widget_table.tscn"),
	"Heatmap" : preload("res://components/dashboard/widget_heatmap/widget_heatmap.tscn"),
	"WorldMap" : preload("res://components/dashboard/widget_world_map/widget_world_map.tscn")
}

signal deleted
signal dashboard_changed(dashboard)
signal dashboard_closed(dashboard)
signal dashboard_maximized(is_maximized)
signal dashboard_edit_enabled

var manager: Node = null
var dashboard_name : String = "" setget set_dashboard_name
var last_saved_name : String = ""
var uuid : String = ""
var is_editing: bool = false

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
var is_maximized: bool = false setget set_is_maximized

var initial_load : bool = true

var previous_scroll : int = 0

onready var date_button := $VBoxContainer/PanelContainer/Content/HFlowContainer/DateButton
onready var dashboard := $VBoxContainer/ScrollContainer/Content/Dashboard
onready var add_widget_popup := $NewWidgetPopup
onready var range_selector := $DateRangeSelector
onready var refresh_option := $"%RefreshOptionButton"
onready var lock_button := $"%DashboardEditButton"
onready var dashboard_scroll := $VBoxContainer/ScrollContainer
onready var references := $VBoxContainer/ScrollContainer/Content/Dashboard/References

onready var clouds_combo := find_node("CloudsCombo")
onready var accounts_combo := find_node("AccountsCombo")
onready var regions_combo := find_node("RegionsCombo")


func _unhandled_input(_event):
	if add_widget_popup.visible:
		get_tree().set_input_as_handled()

func _ready() -> void:
	Style.add($VBoxContainer/MinimizedBar/MinimizeButton, Style.c.LIGHT)
	Style.add(find_node("RefreshIcon"), Style.c.LIGHT)
	
	add_widget_popup.dashboard_container = self
	add_widget_popup.from_date = $DateRangeSelector.from.unix_time
	add_widget_popup.to_date = $DateRangeSelector.to.unix_time
	add_widget_popup.interval = 144
	
	dashboard.dashboard_container = self
	dashboard.ts_start = $DateRangeSelector.from.unix_time
	dashboard.ts_end = $DateRangeSelector.to.unix_time
	dashboard.step = 144
	
	self.dashboard_name = name
	
	if InfrastructureInformation.infra_info != []:
		_on_infra_info_updated()
	InfrastructureInformation.connect("infra_info_updated", self, "_on_infra_info_updated")
	
	dashboard.lock(true)


func _process(_delta):
	if dashboard_scroll.scroll_vertical != previous_scroll:
		previous_scroll = dashboard_scroll.scroll_vertical
		references.mouse_filter = MOUSE_FILTER_STOP
		$VBoxContainer/ScrollContainer/ScrollTimer.start()

func show_popup_bg():
	$PopupBG.show()


func hide_popup_bg():
	$PopupBG.hide()


func _on_AddWidgetButton_pressed() -> void:
	add_widget_popup.add_widget_popup()


func _on_WidgetContainer_config_pressed(widget_container) -> void:
	add_widget_popup.edit_widget(widget_container)


func _on_WidgetContainer_duplicate_pressed(widget_container) -> void:
	add_widget_popup.duplicate_widget(widget_container)


func _on_DateButton_pressed() -> void:
	$DateRangeSelector.rect_global_position.y = date_button.rect_global_position.y + date_button.rect_size.y
	$DateRangeSelector.rect_position.x = rect_size.x / 2 - $DateRangeSelector.rect_size.x / 2
	$DateRangeSelector.popup()


func _on_DateRangeSelector_range_selected(start : int, end : int, text : String) -> void:
	date_button.text = text
	var time_range_in_hours = float(end-start)/3600
	add_widget_popup.from_date = start
	add_widget_popup.to_date = end
	add_widget_popup.interval = max(int(float(end-start)/500.0), min_resolution/time_range_in_hours)
	dashboard.ts_end = end
	dashboard.ts_start = start
	dashboard.step = max(int(float(end-start)/500.0), min_resolution/time_range_in_hours)
	force_refresh = true
	if initial_load:
		emit_signal("dashboard_changed", self)


func get_class():
	return "DashboardContainer"


func _on_DashboardEditButton_toggled(button_pressed : bool) -> void:
	is_editing = button_pressed
	$"%DashboardAddWidgetButton".visible = is_editing
	dashboard.lock(!is_editing)
	if !is_editing:
		emit_signal("dashboard_changed", self)
	else:
		emit_signal("dashboard_edit_enabled")


func _on_OptionButton_item_selected(_index : int) -> void:
	kebap_popup.hide()
	var text : String = refresh_option.text
	text = text.replace("min", "*60")
	text = text.replace("hr", "*3600")
	var expression = Expression.new()
	expression.parse(text)
	refresh_time = expression.execute()


func _on_DeleteButton_pressed() -> void:
	kebap_popup.hide()
	var delete_title = "Delete Dashboard?"
	var delete_message = "Do you want to delete the dashboard \"" + dashboard_name + "\"?"
	
	if manager and dashboard_name == manager.DefaultDashboardName:
		delete_title = "Reset Dashboard?"
		delete_message = "%s can not be deleted. Do you want to reset the dashboard?" % manager.DefaultDashboardName
	
	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		delete_title,
		delete_message,
		"Yes", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String):
	if _response == "left":
		emit_signal("deleted", get_position_in_parent(), last_saved_name)
		queue_free()
		Analytics.event(Analytics.EventsDashboard.DELETE)


func set_dashboard_name(new_name : String) -> void:
	name = new_name
	dashboard_name = new_name
	find_node("DashboardMinLabel").text = new_name


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
	if option == "All":
		option = ""
	dashboard.filters["account"] = option
	account = option
	add_widget_popup.dashboard_filters["account"] = option
	force_refresh = true
	
	if initial_load:
		emit_signal("dashboard_changed", self)


func _on_RegionsCombo_option_changed(option):
	if option == "All":
		option = ""
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
		"ui_version" : _g.ui_version,
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
		container.size_on_grid.x = max(settings["size:x"], 1)
		container.size_on_grid.y = max(settings["size:y"], 1)
		container.rect_position = Vector2(settings["position:x"], settings["position:y"]) * container.grid_size
		container.rect_size = Vector2(settings["size:x"], settings["size:y"]) * container.grid_size
		container.parent_reference.rect_size = container.rect_size
		container.parent_reference.rect_position = container.rect_position


func _on_NewWidgetPopup_widget_added(_widget_data, _show):
	force_refresh = true
	emit_signal("dashboard_changed", self)


func _on_ExportButton_pressed():
	kebap_popup.hide()
	if OS.has_feature("HTML5"):
		JavaScript.download_buffer(JSON.print(get_data(),"\t").to_utf8(), "%s.json" % dashboard_name)
	else:
		Utils.save_string_to_json("user://dashboard_%s.json" % dashboard_name, JSON.print(get_data(),"\t"))


func _on_CloseButton_pressed():
	kebap_popup.hide()
	if not is_editing:
		emit_signal("dashboard_changed", self)
		emit_signal("dashboard_closed", self)
		return
	
	var close_confirm_popup = _g.popup_manager.show_confirm_popup(
		"Save changes before closing Dashboard?",
		"Do you want to save the current changes in this dashboard before closing?",
		"Yes", "No")
	close_confirm_popup.connect("response", self, "_on_close_confirm_response", [], CONNECT_ONESHOT)


func _on_close_confirm_response(_response:String):
	if _response == "left":
		emit_signal("dashboard_changed", self)
	emit_signal("dashboard_closed", self)


func set_is_maximized(_is_maximized:bool):
	is_maximized = _is_maximized
	$VBoxContainer/PanelContainer.visible = !is_maximized
	$VBoxContainer/MinimizedBar.visible = is_maximized
	emit_signal("dashboard_maximized", is_maximized)


func _on_MaximizeButton_pressed():
	set_is_maximized(true)


func _on_MinimizeButton_pressed():
	set_is_maximized(false)


func _on_RenameButton_pressed():
	kebap_popup.hide()
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Rename Configuration",
		"Enter a new name for the dashboard:\n`%s`" % last_saved_name,
		last_saved_name,
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_rename_confirm_response", [], CONNECT_ONESHOT)


func _on_rename_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		set_dashboard_name(_value)
		if initial_load:
			emit_signal("dashboard_changed", self)
		last_saved_name = _value


onready var kebap_button = $"%KebapButton"
onready var kebap_popup:= $KebapPopup
func _on_KebapButton_pressed():
	kebap_popup.popup(Rect2(kebap_button.rect_global_position+Vector2(kebap_button.rect_size), Vector2.ONE))


func _on_NewWidgetPopup_widget_edited():
	emit_signal("dashboard_changed", self)


func _on_DashboardContainer_visibility_changed():
	if not visible and is_editing:
		add_widget_popup._close_popup()
		$"%DashboardEditButton".pressed = false


func _on_RefreshTimer_timeout():
	if not is_visible_in_tree():
		return
	var current_time := Time.get_unix_time_from_system()
	if current_time - last_refresh > refresh_time or force_refresh:
		print("Refresh dashboard (%s): %s - forced: %s" % [last_saved_name, Time.get_datetime_string_from_system(false,true), force_refresh])
		last_refresh = current_time
		dashboard.refresh()
		force_refresh = false

func _notification(what):
	if what == NOTIFICATION_WM_FOCUS_IN:
		$RefreshTimer.start()


func _on_ScrollTimer_timeout():
	references.mouse_filter = MOUSE_FILTER_IGNORE
