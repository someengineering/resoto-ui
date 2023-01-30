extends PanelContainer

signal source_changed
signal delete_source(node)

var widget : BaseWidget setget set_widget
var datasource_type : int =  DataSource.TYPES.TIME_SERIES

onready var data_source : DataSource setget set_data_source

# Title Bar
onready var expand_button := $VBox/Title/ExpandButton

# Time Series Data Source
onready var function_options := $VBox/TimeSeries/MainPart/FunctionVBox/FunctionComboBox
onready var metrics_options := $VBox/TimeSeries/MainPart/MetricsVBox/MetricsOptions
onready var filters_widget := $VBox/TimeSeries/FilterWidget
onready var date_offset_edit := $VBox/TimeSeries/DateOffset/DateOffsetLineEdit
onready var by_line_edit := $VBox/TimeSeries/SumBy/SumByLineEdit
onready var sum_by_help := $VBox/TimeSeries/SumBy/SumByTitle/SumByHelp

# Search Data Source
onready var kinds_combo_box := $VBox/Search/HBoxContainer/KindsComboBox
onready var kinds_line_edit := $VBox/Search/LineEditKinds
onready var text_line_edit := $VBox/Search/TextLineEdit
onready var text_filters_line_edit := $VBox/Search/TextFiltersLineEdit
onready var list_line_edit := $VBox/Search/ListLineEdit

# Two Entries Aggregate
onready var entry_1_line_edit := $VBox/TwoEntriesAggregate/EntryContainer1/Entry1LineEdit
onready var entry_2_line_edit := $VBox/TwoEntriesAggregate/EntryContainer2/Entry2LineEdit
onready var entry_1_alias_line_edit := $VBox/TwoEntriesAggregate/EntryContainer1/Entry1Alias
onready var entry_2_alias_line_edit := $VBox/TwoEntriesAggregate/EntryContainer2/Entry2Alias
onready var function_line_edit := $VBox/TwoEntriesAggregate/FunctionContainer/FunctionLineEdit
onready var function_alias_line_edit := $VBox/TwoEntriesAggregate/FunctionContainer/FunctionAlias
onready var kinds_combobox_two_entries_datasource := $VBox/TwoEntriesAggregate/KindComboBox

# Aggregation would make sense!


# Resulting Query Box
onready var resulting_query_sep := $VBox/ResultingQueryBox
onready var resulting_query_label := $VBox/ResultingQueryBox/QueryLabel

onready var query_editbox_label := $VBox/QueryEditVBox/QueryLabel

# Query Edit
onready var query_edit := $VBox/QueryEditVBox/QueryEdit

var interval : int = 3600


func _ready() -> void:
	Style.add_self(self, Style.c.BG)
	
	$VBox/TimeSeries.visible = datasource_type == DataSource.TYPES.TIME_SERIES
	$VBox/Search.visible = datasource_type == DataSource.TYPES.SEARCH
	$VBox/TwoEntriesAggregate.visible = datasource_type == DataSource.TYPES.TWO_ENTRIES_AGGREGATE
	$VBox/AggregateSearch.visible = datasource_type == DataSource.TYPES.AGGREGATE_SEARCH
	update_time_series_sum_by()
	
	match datasource_type:
		DataSource.TYPES.TIME_SERIES:
			data_source = TimeSeriesDataSource.new()
		DataSource.TYPES.AGGREGATE_SEARCH:
			data_source = AggregateSearchDataSource.new()
		DataSource.TYPES.SEARCH:
			data_source = TextSearchDataSource.new()
			API.cli_execute("kinds", self)
		DataSource.TYPES.TWO_ENTRIES_AGGREGATE:
			data_source = TwoEntryAggregateDataSource.new()
			API.cli_execute("kinds", self)
	
	$"%TitleLabel".text = "Data Source %s - %s" % [str(get_parent().get_children().find(self)+1), DataSource.TYPES.keys()[data_source.type].capitalize()]
	
	data_source.widget = widget
	data_source.connect("query_status", self, "_on_data_source_query_status")
	query_edit.connect("focus_exited", self, "_on_QueryEdit_focus_exited")
	
	update_query_label_text()
	add_child(data_source)


func _on_cli_execute_done(_error : int, response):
	var kinds = response.transformed.result.split("\n")
	
	if kinds.size() > 0:
		$VBox/Search/HBoxContainer/KindsComboBox.set_items(kinds)
		$VBox/TwoEntriesAggregate/KindComboBox.set_items(kinds)

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
	if _error:
		return
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
	
	filters_widget.set_labels(labels)
	filters_widget.set_values([])


func update_query(force_query := false) -> void:
	var query = data_source.query
	data_source.custom_query = false
	
	data_source.update_query()
	if data_source.query != query or force_query:
		query_edit.text = data_source.query
		_on_QueryEdit_item_rect_changed()
		emit_signal("source_changed")


func set_widget(new_widget : BaseWidget) -> void:
	widget = new_widget
	data_source.widget = new_widget


func _on_stack_changed(button_pressed : bool) -> void:
	if data_source.stacked == button_pressed:
		return
	data_source.stacked = button_pressed
	update_query(true)


func _on_legend_changed(new_text : String) -> void:
	data_source.legend = new_text
	update_query(true)


func _on_FunctionComboBox_option_changed(option) -> void:
	data_source.aggregator = option
	update_query()


func _on_FilterWidget_filter_changed(filter:String, filter_dicts:Array) -> void:
	data_source.filters = filter
	data_source.filter_dicts = filter_dicts
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
	query_edit.rect_min_size.y = max((row_count*25)+10, 36)

func execute_query_edit():
	data_source.query = query_edit.text
	emit_signal("source_changed")


func _on_QueryEdit_text_changed():
	_on_QueryEdit_item_rect_changed()
	data_source.custom_query = true
	expand_button.pressed = false


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
	update_time_series_sum_by()
	var error_icon = $"%ErrorIcon"
	var tooltip = "[b][color=#%s]%s[/color][/b]" % [Style.col_map[Style.c.ERR_MSG].to_html(), _title]
	if _message != "":
		tooltip += "\n" + _message
	match _status:
		OK:
			# Update the Help for time series legends
			if "last_metric_keys" in data_source:
				update_time_series_sum_by(data_source.last_metric_keys)
			error_icon.hide()
			hint_tooltip = ""
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
	tooltip.get_node("Text").set_bbcode(for_text)
	return tooltip


func set_data_source(new_data_source : DataSource) -> void:
	data_source.copy_data_source(new_data_source)
	match new_data_source.type:
		DataSource.TYPES.TIME_SERIES:
			metrics_options.text = new_data_source.metric
			filters_widget.filter_dicts = new_data_source.filter_dicts
			filters_widget.filters = new_data_source.filters
			date_offset_edit.text = new_data_source.offset
			by_line_edit.text = new_data_source.sum_by
			function_options.text = new_data_source.aggregator
			data_source.query = new_data_source.query
			data_source.custom_query = new_data_source.custom_query
		DataSource.TYPES.SEARCH:
			data_source.custom_query = new_data_source.custom_query
			kinds_line_edit.text = new_data_source.kinds
			text_line_edit.text = new_data_source.text_to_search
			text_filters_line_edit.text = new_data_source.filters
			list_line_edit.text = new_data_source.list
		DataSource.TYPES.TWO_ENTRIES_AGGREGATE:
			data_source.custom_query = new_data_source.custom_query
			entry_1_line_edit.text = new_data_source.category_1
			entry_2_line_edit.text = new_data_source.category_2
			entry_1_alias_line_edit.text = new_data_source.category_1_alias
			entry_2_alias_line_edit.text = new_data_source.category_2_alias
			function_line_edit.text = new_data_source.function
			function_alias_line_edit.text = new_data_source.function_alias
			kinds_combobox_two_entries_datasource.text = new_data_source.kind 
			
	$VBox/Title/ExpandButton.pressed = !new_data_source.custom_query
	show_query_separator(!new_data_source.custom_query)
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
	$VBox/TimeSeries.visible = button_pressed and datasource_type == DataSource.TYPES.TIME_SERIES
	$VBox/Search.visible = button_pressed and datasource_type == DataSource.TYPES.SEARCH
	$VBox/TwoEntriesAggregate.visible = button_pressed and datasource_type == DataSource.TYPES.TWO_ENTRIES_AGGREGATE
	$VBox/AggregateSearch.visible = button_pressed and datasource_type == DataSource.TYPES.AGGREGATE_SEARCH
	show_query_separator(button_pressed)


func _on_KindComboBox_option_changed(option):
	data_source.kind = option
	update_query()


func _on_Entry1LineEdit_text_entered(new_text):
	data_source.category_1 = new_text
	update_query()


func _on_Entry2LineEdit_text_entered(new_text):
	data_source.category_2 = new_text
	update_query()


func _on_Entry1Alias_text_entered(new_text:String):
	new_text = new_text.replace(" ", "_")
	$VBox/TwoEntriesAggregate/EntryContainer1/Entry1Alias.text = new_text
	data_source.category_1_alias = new_text
	update_query()


func _on_Entry2Alias_text_entered(new_text:String):
	new_text = new_text.replace(" ", "_")
	$VBox/TwoEntriesAggregate/EntryContainer2/Entry2Alias.text = new_text
	data_source.category_2_alias = new_text
	update_query()


func _on_FunctionLineEdit_text_entered(new_text):
	data_source.function = new_text
	update_query()


func _on_FunctionAlias_text_entered(new_text):
	data_source.function_alias = new_text
	update_query()


func update_time_series_sum_by(last_metric_keys:Array=[]):
	var help_text_legend := "[b]Set the legend on the widget.[/b]\nIf the result contains labels, you can display them by wrapping it in curly braces.\n"
	help_text_legend += "[b]Examples[/b]\n- [code]{label_name}[/code]\n- [code]Cloud: {cloud}[/code]%s"
	var help_text_sum_by := "[b]Sum by a label in the metric.[/b]%s"
	if not last_metric_keys.empty():
		var last_metric_string : PoolStringArray = []
		for key in last_metric_keys:
			last_metric_string.append("[code]{%s}[/code]" % key)
		help_text_legend = help_text_legend % str("\n\nThe last query returned the following labels:\n[code]%s[/code]" % last_metric_string.join(", "))
		help_text_sum_by = help_text_sum_by % str("\n\nThe last query returned the following labels:\n[code]%s[/code]" % last_metric_string.join(", "))
	else:
		help_text_legend = help_text_legend % ""
#		help_text_sum_by = help_text_sum_by % ""
#	legend_help.tooltip_text = help_text_legend
	sum_by_help.tooltip_text = help_text_sum_by


func show_query_separator(_show:bool=false):
	resulting_query_sep.visible = _show
	query_editbox_label.visible = !_show


func _on_GroupVariables_group_variables_changed(grouping_variables):
	data_source.grouping_variables = grouping_variables
	update_query()


func _on_GroupFunctions_group_variables_changed(grouping_variables):
	data_source.grouping_functions = grouping_variables
	update_query()


func _on_AggregateSearchQuery_text_entered(new_text):
	data_source.search_query = new_text
	update_query()


func update_query_label_text():
	var label_text : String = ""
	match datasource_type:
		DataSource.TYPES.TIME_SERIES:
			label_text = "Query"
		DataSource.TYPES.SEARCH:
			label_text = "Resoto Search"
		_:
			label_text = "Aggregate Search"
			
	query_editbox_label.text = label_text
	resulting_query_label.text = label_text
