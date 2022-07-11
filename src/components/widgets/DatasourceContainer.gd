extends PanelContainer

signal source_changed

var widget : BaseWidget setget set_widget

onready var metrics_options := $VBoxContainer/DatasourceSettings/VBoxContainer2/MetricsOptions
onready var filters_widget := $VBoxContainer/DatasourceSettings/HBoxContainer/FilterWidget
onready var legend_edit := $VBoxContainer/DatasourceSettings/VBoxContainer5/LegendEdit
onready var function_options := $VBoxContainer/DatasourceSettings/VBoxContainer3/FunctionComboBox
onready var date_offset_edit := $VBoxContainer/DatasourceSettings/VBoxContainer/DateOffsetLineEdit
onready var data_source := DataSource.new()
onready var stacked_check_box := $VBoxContainer/DatasourceSettings/StackedCheckBox

class DataSource extends Node:
	var query : String
	var legend : String
	var widget : BaseWidget
	var stacked : bool = true
	
	func make_query():
		if widget.data_type == BaseWidget.DATA_TYPE.INSTANT:
			API.query_tsdb(query, self)
		else:
			API.query_range_tsdb(query, self)
			
	func _on_query_tsdb_done(error: int, response):
		var data = response.transformed.result
		if data.data.result.size() == 0:
			_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 1)
			return
	
		if widget.data_type == BaseWidget.DATA_TYPE.INSTANT:
			if data["status"] == "success":
				if data["data"]["result"].size() > 0:
					widget.value = data["data"]["result"][0]["value"][1]
			else:
				_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],1)
				widget.value = "NaN"
	
	func _on_query_range_tsdb_done(_error:int, response):
		var data = response.transformed.result
		if data.data.result.size() == 0:
			_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 1)
			return
			
		if data["status"] == "success":
			
			var regex = RegEx.new()
			regex.compile("(?<={)(.*?)(?=})")
			var legend_labels : Array = regex.search_all(legend)
			
			var data_size = data.data.result[0].values.size()
			widget.x_origin = data.data.result[0].values[0][0]
			widget.x_range = data.data.result[0].values[data_size-1][0] - widget.x_origin
			
			var maxy = -INF
			
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

func _ready():
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
	var query = function_options.text+"(resoto_"+metrics_options.text + "{%s} %s)"
	var filters : String = filters_widget.get_node("VBoxContainer/LineEdit").text
	var offset : String = date_offset_edit.text
	if offset != "":
		offset = "offset " + offset
	query = query % [filters, offset]
	data_source.query = query
	emit_signal("source_changed")
	
func set_widget(new_widget):
	widget = new_widget
	data_source.widget = new_widget
	var ranged : bool = widget.data_type == BaseWidget.DATA_TYPE.RANGE
	stacked_check_box.visible = ranged
	$Vboxcontainer5.visible = ranged


func _on_StackedCheckBox_toggled(button_pressed):
	data_source.stacked = button_pressed
	update_query()


func _on_LegendEdit_text_entered(new_text):
	data_source.legend = new_text
	update_query()


func _on_FunctionComboBox_option_changed(_option):
	update_query()
