class_name TextSearchDataSource
extends DataSource

var text_to_search : String = ""
var kinds : String = ""
var filters : String = ""
var list : String = ""

func _init():
	type = TYPES.SEARCH

func make_query(dashboard_filters : Dictionary, _attr : Dictionary):
	var q : String = query
	
	var global_filters = ""
	
	if dashboard_filters["cloud"] != "" and dashboard_filters["cloud"] != "All":
		global_filters += " and /ancestors.cloud.reported.name=\"%s\"" % dashboard_filters["cloud"]
	if dashboard_filters["region"] != "" and dashboard_filters["region"] != "All":
		global_filters += " and /ancestors.region.reported.name=\"%s\"" % dashboard_filters["region"]
	if dashboard_filters["account"] != "" and dashboard_filters["account"] != "All":
		global_filters += " and /ancestors.account.reported.name=\"%s\"" % dashboard_filters["account"]
	if "{global_filters}" in q:
		q = q.replace("{global_filters}", global_filters)
	else:
		q += global_filters
	set_request(API.graph_search(q, self, "list"))


func _on_graph_search_done(_error : int, response):
	if _error == ERR_PRINTER_ON_FIRE:
		emit_signal("query_status", _error, "Query canceled")
		return
	if _error:
		var error_detail := ""
		if response:
			error_detail = "\n\n" + response.body.get_string_from_utf8()
		emit_signal("query_status", FAILED, "Invalid Search", "There is a problem with the search query.%s" % error_detail)
		return
	var result : Array = response.transformed.result
	if "Error: " in response.transformed.result:
		_g.emit_signal("add_toast", "Invalid query", result, 1, self)
		emit_signal("query_status", FAILED, "Invalid query", result)
		return
	if is_instance_valid(widget):
		widget.set_data(result, type)
		emit_signal("query_status", OK, "")

	
func copy_data_source(other : TextSearchDataSource):
	text_to_search = other.text_to_search
	kinds = other.kinds
	filters = other.filters
	list = other.list
	query = other.query
	custom_query = other.custom_query


func update_query():
	query = text_to_search
	
	if kinds != "":
		if query != "":
			query += " and "
		query += "is(%s)" % kinds
		
	if query == "":
		query = "all"
		
	query += "{global_filters}"
	
	if filters != "":
		query += " and %s" % filters


func get_data() -> Dictionary:
	var data : Dictionary = {
		"text_to_search" : text_to_search,
		"kinds" : kinds,
		"filters" : filters,
		"list" : list
	}
	
	data.merge(.get_data())
	
	return data
