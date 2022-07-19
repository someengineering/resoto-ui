extends PanelContainer

signal source_changed

var widget : BaseWidget setget set_widget
var data_source

onready var metrics_options := $VBoxContainer/DatasourceSettings/VBoxContainer2/MetricsOptions
onready var filters_widget := $VBoxContainer/DatasourceSettings/HBoxContainer/FilterWidget
onready var legend_edit := $VBoxContainer/DatasourceSettings/VBoxContainer5/LegendEdit
onready var function_options := $VBoxContainer/DatasourceSettings/VBoxContainer3/FunctionComboBox
onready var date_offset_edit := $VBoxContainer/DatasourceSettings/VBoxContainer/DateOffsetLineEdit
onready var stacked_check_box := $VBoxContainer/DatasourceSettings/StackedCheckBox
onready var by_line_edit := $VBoxContainer/DatasourceSettings/VBoxContainer4/ByLineEdit
onready var query_edit := $VBoxContainer/VBoxContainer/QueryEdit

var interval : int = 3600


class DataSource extends Node:
	var query : String
	var legend : String
	var widget : BaseWidget
	var stacked : bool = true
	var interval : int = 3600
	var from : int = Time.get_unix_time_from_system() - 3600 * 24
	var to : int = Time.get_unix_time_from_system()
	
	func make_query():
		var q = query.replace("$interval", "%ds" % (interval*2))
		if widget.data_type == BaseWidget.DATA_TYPE.INSTANT:
			API.query_tsdb(q, self)
		else:
			widget.step = interval
			widget.x_origin = from
			widget.x_range = to - from
			API.query_range_tsdb(q, self, from, to, interval)
			
	func _on_query_tsdb_done(_error: int, response):
		var data = response.transformed.result
		
		if _error != 0 or typeof(data) == TYPE_STRING:
			_g.emit_signal("add_toast", "Request Error", data, 1)
			
		if data.data.result.size() == 0:
			_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 1)
			return
	
		if data["status"] == "success":
			if data["data"]["result"].size() > 0:
				widget.value = data["data"]["result"][0]["value"][1]
		else:
			_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],1)
			widget.value = "NaN"
	
	func _on_query_range_tsdb_done(_error:int, response):
		var data = response.transformed.result
		
		if _error != 0 or typeof(data) == TYPE_STRING:
			_g.emit_signal("add_toast", "Request Error", data, 1)
			
		if data.data.result.size() == 0:
			_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 1)
			return
			
		if data["status"] == "success":
			var regex = RegEx.new()
			regex.compile("(?<={)(.*?)(?=})")
			var legend_labels : Array = regex.search_all(legend)
			
			var data_size = data.data.result[0].values.size()
			
			
			for serie in data.data.result:
				var array : PoolVector2Array = []
				array.resize(serie.values.size())
				for i in array.size():
					array[i] = Vector2(serie.values[i][0], serie.values[i][1])
					
				var l : String = legend
				for label in legend_labels:
					var replace := ""
					if label.strings[0] in serie.metric:
						replace =serie.metric[label.strings[0]]
					l = l.replace("{%s}"%label.strings[0], replace)
				widget.add_serie(array, null, l, stacked)
			widget.complete_update(true)
		else:
				_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],1)
				widget.value = "NaN"

func _ready():
	data_source = DataSource.new()
	data_source.interval = interval
	data_source.widget = widget

func _on_Button_toggled(button_pressed):
	$VBoxContainer/DatasourceSettings.visible = not button_pressed

func _on_DeleteButton_pressed():
	queue_free()


func set_metrics(metrics : Dictionary):
	metrics_options.clear()
	for metric in  metrics:
		metrics_options.add_item(metric)


func _on_MetricsOptions_option_changed(option):
	update_query()
	API.query_tsdb("resoto_"+option, self, "_on_metrics_query_finished")


func _on_metrics_query_finished(error:int, response):
	var labels := []
	var data = response.transformed.result
	for label in data.data.result[0].metric:
		if not label.begins_with("__"):
			labels.append(label)
	
	filters_widget.labels.set_items(labels)
	
	filters_widget.value.set_items([])


func update_query():
	var query = "resoto_"+metrics_options.text
	var filters : String = filters_widget.get_node("VBoxContainer/LineEdit").text
	var offset : String = date_offset_edit.text
	if filters != "":
		query = "%s{%s}" % [query, filters]
	if offset != "":
		offset = "offset " + offset
		query = "%s %s" % [query, offset]
	if function_options.text != "":
		if "_over_time" in function_options.text:
			query = "%s[$interval]" % [query]
		query = "%s(%s)" % [function_options.text, query]
	if by_line_edit.text != "":
		query = "sum(%s) by %s" % [query, by_line_edit.text]
		
	if data_source.query != query:
		data_source.query = query
		query_edit.text = query
		emit_signal("source_changed")
	
func set_widget(new_widget):
	widget = new_widget
	data_source.widget = new_widget
	var ranged : bool = widget.data_type == BaseWidget.DATA_TYPE.RANGE
	stacked_check_box.visible = ranged
	legend_edit.get_parent().visible = ranged


func _on_StackedCheckBox_toggled(button_pressed):
	data_source.stacked = button_pressed
	update_query()


func _on_LegendEdit_text_entered(new_text):
	data_source.legend = new_text
	update_query()


func _on_FunctionComboBox_option_changed(_option):
	update_query()


func _on_FilterWidget_filter_changed(_filter):
	update_query()


func _on_DateOffsetLineEdit_text_entered(_new_text):
	update_query()


func _on_ByLineEdit_text_entered(_new_text):
	update_query()


func _on_QueryEdit_text_entered(new_text):
	data_source.query = new_text
	emit_signal("source_changed")
