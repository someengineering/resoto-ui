extends PanelContainer

signal source_changed
signal delete_source(node)

var widget : BaseWidget setget set_widget
var datasource_type : int =  DataSource.TYPES.TIME_SERIES
onready var data_source : DataSource setget set_data_source

onready var metrics_options := $VBoxContainer/DatasourceSettings/MetricsVBox/MetricsOptions
onready var filters_widget := $VBoxContainer/DatasourceSettings/FilterHBox/FilterWidget
onready var legend_edit := $VBoxContainer/DatasourceSettings/VBoxContainer5/LegendEdit
onready var function_options := $VBoxContainer/DatasourceSettings/FunctionVBox/FunctionComboBox
onready var date_offset_edit := $VBoxContainer/DatasourceSettings/VBoxContainer/DateOffsetLineEdit
onready var stacked_check_box := $VBoxContainer/DatasourceSettings/StackedCheckBox
onready var by_line_edit := $VBoxContainer/DatasourceSettings/VBoxContainer4/ByLineEdit
onready var query_edit := $VBoxContainer/QueryEditVBox/QueryEdit
onready var expand_button := $VBoxContainer/HBoxContainer/ExpandButton
onready var kinds_combo_box := $VBoxContainer/TextSearchSettings/HBoxContainer/KindsComboBox
onready var kinds_line_edit := $VBoxContainer/TextSearchSettings/LineEditKinds
onready var text_line_edit := $VBoxContainer/TextSearchSettings/TextLineEdit
onready var text_filters_line_edit := $VBoxContainer/TextSearchSettings/TextFiltersLineEdit
onready var list_line_edit := $VBoxContainer/TextSearchSettings/ListLineEdit

var interval : int = 3600


func _ready() -> void:
	$"%TitleLabel".text = "Data Source %s" % str(get_parent().get_children().find(self)+1)
	Style.add_self(self, Style.c.BG)
	match datasource_type:
		DataSource.TYPES.TIME_SERIES:
			data_source = TimeSeriesDataSource.new()
			$VBoxContainer/DatasourceSettings.show()
			$VBoxContainer/TextSearchSettings.hide()
		DataSource.TYPES.AGGREGATE_SEARCH:
			data_source = AggregateSearchDataSource.new()
			$VBoxContainer/DatasourceSettings.hide()
			$VBoxContainer/TextSearchSettings.hide()
			expand_button.hide()
		DataSource.TYPES.SEARCH:
			data_source = TextSearchDataSource.new()
			$VBoxContainer/DatasourceSettings.hide()
			$VBoxContainer/TextSearchSettings.show()
			API.cli_execute("kinds", self)
	data_source.widget = widget
	data_source.connect("query_status", self, "_on_data_source_query_status")
	query_edit.connect("focus_exited", self, "_on_QueryEdit_focus_exited")


func _on_cli_execute_done(error : int, response):
	var kinds = response.transformed.result.split("\n")
	
	if kinds.size() > 0:
		$VBoxContainer/TextSearchSettings/HBoxContainer/KindsComboBox.set_items(kinds)


func _on_DeleteButton_pressed() -> void:
	emit_signal("delete_source", self)


func set_metrics(metrics : Dictionary) -> void:
	metrics_options.clear()
	for metric in  metrics:
		metrics_options.add_item(metric)


func _on_MetricsOptions_option_changed(option : String) -> void:
	data_source.metric = option
	update_query()
	API.query_tsdb(_g.tsdb_metric_prefix + option, self, "_on_metrics_query_finished")


func _on_metrics_query_finished(_error:int, response) -> void:
	var labels := []
	var data = response.transformed.result
	
	if data is String and data.begins_with("Error"):
		_g.emit_signal("add_toast", "Error receiving Metrics", "Remote Message: %s" % data, 2, self)
		return
	if data.data.result.size() == 0:
		_g.emit_signal("add_toast", "Can't find Labels", "Can't find labels for the selected metric", 2, self)
		return
	for label in data.data.result[0].metric:
		if not label.begins_with("__") and not label == "cloud" and not label == "region" and not label == "account":
			labels.append(label)
	
	filters_widget.labels.set_items(labels)
	
	filters_widget.value.set_items([])


func update_query(force_query := false) -> void:
	var query = data_source.query
	
	data_source.update_query()
	if data_source.query != query or force_query:
		query_edit.text = data_source.query
		_on_QueryEdit_item_rect_changed()
		emit_signal("source_changed")


func set_widget(new_widget : BaseWidget) -> void:
	widget = new_widget
	data_source.widget = new_widget
	var ranged : bool = widget.data_type == BaseWidget.DATA_TYPE.RANGE
	stacked_check_box.visible = ranged
	legend_edit.get_parent().visible = ranged


func _on_StackedCheckBox_toggled(button_pressed : bool) -> void:
	data_source.stacked = button_pressed
	update_query(true)


func _on_LegendEdit_text_entered(new_text : String) -> void:
	data_source.legend = new_text
	update_query(true)


func _on_FunctionComboBox_option_changed(option) -> void:
	data_source.aggregator = option
	update_query()


func _on_FilterWidget_filter_changed(filter) -> void:
	data_source.filters = filter
	update_query()


func _on_DateOffsetLineEdit_text_entered(offset) -> void:
	data_source.offset = offset
	update_query()


func _on_ByLineEdit_text_entered(sum_by) -> void:
	data_source.sum_by = sum_by
	update_query()


func reset_error_display():
	$Warning.hide()


var delete_nl:= false
func _on_QueryEdit_focus_exited():
	execute_query_edit()


func _on_QueryEdit_item_rect_changed():
	var row_count = query_edit.get_total_visible_rows()
	query_edit.rect_min_size.y = (row_count*25)+10

func execute_query_edit():
	data_source.query = query_edit.text
	emit_signal("source_changed")


func _on_QueryEdit_text_changed():
	_on_QueryEdit_item_rect_changed()


func _on_QueryEdit_gui_input(event:InputEventKey):
	if event is InputEventKey and event.is_pressed() and event.physical_scancode == KEY_ENTER:
		query_edit.text = query_edit.text.replace("\n", "")
		execute_query_edit()
		query_edit.cursor_set_line(query_text_edit_cursor_pos[0])
		query_edit.cursor_set_column(query_text_edit_cursor_pos[1])
		get_tree().set_input_as_handled()

var query_text_edit_cursor_pos:= []
func _on_QueryEdit_cursor_changed():
	query_text_edit_cursor_pos = [query_edit.cursor_get_line(), query_edit.cursor_get_column()]


func _on_data_source_query_status(_status:int, _title:String, _message:=""):
	var error_icon = $"%ErrorIcon"
	var tooltip = "[b][color=#%s]%s[/color][/b]" % [Style.col_map[Style.c.ERR_MSG].to_html(), _title]
	if _message != "":
		tooltip += "\n" + _message
	match _status:
		OK:
			error_icon.hide()
			$Warning.hide()
		FAILED:
			error_icon.show()
			hint_tooltip = tooltip
			$Warning.show()
		ERR_QUERY_FAILED:
			error_icon.show()
			hint_tooltip = tooltip
			$Warning.show()


func _make_custom_tooltip(for_text):
	var tooltip = preload("res://components/shared/custom_bb_hint_tooltip_error.tscn").instance()
	tooltip.get_node("Text").bbcode_text = for_text
	return tooltip


func set_data_source(new_data_source : DataSource) -> void:
	data_source.copy_data_source(new_data_source)
	match new_data_source.type:
		DataSource.TYPES.TIME_SERIES:
			metrics_options.text = new_data_source.metric
			filters_widget.line_edit.text = new_data_source.filters
			date_offset_edit.text = new_data_source.offset
			by_line_edit.text = new_data_source.sum_by
			function_options.text = new_data_source.aggregator
			data_source.query = new_data_source.query
			legend_edit.text = new_data_source.legend
			stacked_check_box.pressed = new_data_source.stacked
		DataSource.TYPES.SEARCH:
			kinds_line_edit.text = new_data_source.kinds
			text_line_edit.text = new_data_source.text_to_search
			text_filters_line_edit.text = new_data_source.filters
			list_line_edit.text = new_data_source.list
		
	query_edit.text = new_data_source.query
	_on_QueryEdit_item_rect_changed()


func _on_LineEdit_text_entered(new_text):
	data_source.text_to_search = new_text
	update_query()


func _on_LineEdit2_text_entered(new_text):
	data_source.kinds = new_text
	update_query()


func _on_LineEdit4_text_entered(new_text):
	data_source.list = new_text
	update_query()


func _on_LineEdit3_text_entered(new_text):
	data_source.filters = new_text
	update_query()


func _on_KindsComboBox_option_changed(option):
	if kinds_line_edit.text != "":
		kinds_line_edit.text += ", "
	kinds_line_edit.text += option
	data_source.kinds = kinds_line_edit.text
	update_query()


func _on_ExpandButton_toggled(button_pressed:bool):
	$VBoxContainer/DatasourceSettings.visible = button_pressed and datasource_type == DataSource.TYPES.TIME_SERIES
	$VBoxContainer/TextSearchSettings.visible = button_pressed and datasource_type == DataSource.TYPES.SEARCH
