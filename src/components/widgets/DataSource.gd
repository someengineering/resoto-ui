class_name DataSource
extends Node

var query : String
var legend : String
var widget : BaseWidget
var stacked : bool = true

func make_query(from, to, interval) -> void:
	var q = query.replace("$interval", "%ds" % (interval*2))
	if widget.data_type == BaseWidget.DATA_TYPE.INSTANT:
		API.query_tsdb(q, self)
	else:
		widget.step = interval
		widget.x_origin = from
		widget.x_range = to - from
		API.query_range_tsdb(q, self, from, to, interval)
		
func _on_query_tsdb_done(_error: int, response) -> void:
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

func _on_query_range_tsdb_done(_error:int, response) -> void:
	var data = response.transformed.result
	
	if _error != 0 or typeof(data) == TYPE_STRING:
		_g.emit_signal("add_toast", "Request Error", data, 1)
		return
		
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
