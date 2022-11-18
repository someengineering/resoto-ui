class_name TimeSeriesDataSource
extends DataSource

# Variables for data source container
var metric : String = ""
var aggregator : String = ""
var filters : String = ""
var offset : String = ""
var legend : String = ""
var sum_by : String = ""
var stacked : bool = true
# query, now saved to display correctly in toasts and log
var q: String

var making_query := false

func _init():
	type = TYPES.TIME_SERIES

func make_query(dashboard_filters : Dictionary, attr : Dictionary) -> void:
	var interval = attr["interval"]
	if making_query:
		return
	q = query.replace("$interval", "%ds" % (interval))
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
		making_query = true
		q += "&time=%d" % attr["to"]
		set_request(API.query_tsdb(q, self))
	else:
		var from = attr["from"]
		var to = attr["to"]
		widget.step = interval
		widget.x_origin = from
		widget.x_range = to - from
		making_query = true
		set_request(API.query_range_tsdb(q, self, from, to, interval))


func _on_query_tsdb_done(_error: int, response:ResotoAPI.Response) -> void:
	making_query = false
	if _error:
		if response.response_code == 400:
			emit_signal("query_status", FAILED, "400: Bad Request", "Is the time series database running?\nIs resoto.core.api.tsdb_proxy_url correctly configured?")
		return
	if not is_instance_valid(widget):
		return
	
	var data = response.transformed.result
	
	if _error != 0 or data.has("error") or typeof(data) == TYPE_STRING:
		if data.has("error"):
			_g.emit_signal("add_toast", "Request Error", data.error, 1, self)
			emit_signal("query_status", FAILED, "Request Error", data.error)
		else:
			_g.emit_signal("add_toast", "Request Error", data, 1, self)
			emit_signal("query_status", FAILED, "Request Error", data)
		return
	
	if not data.has("data"):
		widget.value = 0
		return
	
	if data.data.result.size() == 0:
		_g.emit_signal("add_toast", "Empty TSDB result.", "", 2, self)
		emit_signal("query_status", ERR_QUERY_FAILED, "Empty TSDB result.")
		widget.value = 0
		return

	if data["status"] == "success":
		var n : int = data["data"]["result"].size()
		if n > 0:
			if widget.single_value:
				if n == 1:
					emit_signal("query_status", OK, "")
					widget.value = data["data"]["result"][0]["value"][1]
				else:
					var warning_title := "Multiple values for single value widget."
					var warning_body := "This widget accept just one value, but the query result has %d" % n
					_g.emit_signal("add_toast", warning_title, warning_body, 2, self)
					emit_signal("query_status", ERR_QUERY_FAILED, warning_title, warning_body)
			else:
				emit_signal("query_status", OK, "")
	else:
		_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"], 1, self)
		emit_signal("query_status", FAILED, "TSDB Query Error %s" % data["errorType"], data["error"])
		widget.value = "NaN"


func _on_query_range_tsdb_done(_error:int, response:ResotoAPI.Response) -> void:
	if _error:
		if response.response_code == 400:
			emit_signal("query_status", FAILED, "400: Bad Request", "Is the time series database running?\nIs resoto.core.api.tsdb_proxy_url correctly configured?")
		return
	making_query = false
	if not is_instance_valid(widget):
		return
	
	var data = response.transformed.result
	
	if _error != 0 or data.has("error") or typeof(data) == TYPE_STRING:
		if data.has("error"):
			_g.emit_signal("add_toast", "Request Error", data.error, 1, self)
			emit_signal("query_status", FAILED, "Request Error", data.error)
		else:
			_g.emit_signal("add_toast", "Request Error", data, 1, self)
			emit_signal("query_status", FAILED, "Request Error", data)
		return
	
	if not data.has("data"):
		return
	
	if data.data.result.size() == 0:
		widget.clear_series()
		_g.emit_signal("add_toast", "Empty TSDB result.", "", 2, self)
		emit_signal("query_status", FAILED, "Empty TSDB result.")
		return
		
	if data["status"] == "success":
		var regex = RegEx.new()
		regex.compile("(?<={)(.*?)(?=})")
		var legend_labels : Array = regex.search_all(legend)
		
		for serie in data.data.result:
			var array : PoolVector2Array = []
			array.resize(serie.values.size())
			for i in array.size():
				array[i] = Vector2(serie.values[i][0] - widget.x_origin, serie.values[i][1])
			
			var l : String = legend
			for label in legend_labels:
				var replace := ""
				if label.strings[0] in serie.metric:
					replace =serie.metric[label.strings[0]]
				l = l.replace("{%s}"%label.strings[0], replace)
			widget.add_serie(array, null, l, stacked)
		
		emit_signal("query_status", OK, "")
		widget.complete_update(true)
	else:
			_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],2, self)
			emit_signal("query_status", FAILED, "TSDB Query Error %s" % data["errorType"], data["error"])
			widget.value = "NaN"
			

func copy_data_source(other : TimeSeriesDataSource) -> void:
	metric = other.metric
	aggregator = other.aggregator
	filters = other.filters
	query = other.query
	stacked = other.stacked
	offset = other.offset
	sum_by = other.sum_by
	legend = other.legend
	
func update_query() -> void:
	query = _g.tsdb_metric_prefix + metric
	
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
		"stacked" : stacked,
		"offset" : offset,
		"sum_by" : sum_by,
		"legend" : legend,
	}
	
	data.merge(.get_data())
	
	return data
	
