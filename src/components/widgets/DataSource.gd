class_name DataSource
extends Node

var query : String
var widget : BaseWidget

# Variables for data source container

var metric : String = ""
var aggregator : String = ""
var filters : String = ""
var offset : String = ""
var legend : String = ""
var sum_by : String = ""
var stacked : bool = true



func make_query(from, to, interval, dashboard_filters : Dictionary = {}) -> void:
	var q = query.replace("$interval", "%ds" % (interval))
	if dashboard_filters == {}:
		q = q.replace("$dashboard_filters,", "")
		q = q.replace("$dashboard_filters", "")
	else:
		var d_filters : PoolStringArray = []
		for key in dashboard_filters:
			if dashboard_filters[key] != "":
				d_filters.append('%s=~"%s"' % [key, dashboard_filters[key]])

		var filters_str = d_filters.join(",")
		if filters_str == "":
			q = q.replace("$dashboard_filters,", "")
		q = q.replace("$dashboard_filters", filters_str)
		
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
		_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 2)
		widget.value = 0
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
		widget.clear_series()
		_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 2)
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
			_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],2)
			widget.value = "NaN"
			

func copy_data_source(other : DataSource) -> void:
	metric = other.metric
	aggregator = other.aggregator
	filters = other.filters
	query = other.query
	stacked = other.stacked
	offset = other.offset
	sum_by = other.sum_by
	legend = other.legend
	
func update_query() -> void:
	query = "resoto_" + metric
	
	if filters != "":
		query = "%s{$dashboard_filters, %s}" % [query, filters]
	else:
		query = "%s{$dashboard_filters}" % query
	if offset != "":
		offset = "offset " + offset
		query = "%s %s" % [query, offset]
	if aggregator != "":
		if "_over_time" in aggregator:
			query = "%s[$interval]" % [query]
		query = "%s(%s)" % [aggregator, query]
	if sum_by != "":
		query = "sum(%s) by %s" % [query, sum_by]
		

func get_data() -> Dictionary:
	var data : Dictionary = {
		"metric" : metric,
		"aggregator" : aggregator,
		"filters" : filters,
		"query" : query,
		"stacked" : stacked,
		"offset" : offset,
		"sum_by" : sum_by,
		"legend" : legend,
	}
	
	return data
	
