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
	q = q.replace("{global_filters}", global_filters)
	set_request(API.cli_execute(q, self))


func _on_cli_execute_done(_error : int, response):
	if _error == OK:
		var result : String = response.transformed.result
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
		
	query += " | list --csv %s" % list
		
	query = "search " + query


func get_data() -> Dictionary:
	var data : Dictionary = {
		"text_to_search" : text_to_search,
		"kinds" : kinds,
		"filters" : filters,
		"list" : list
	}
	
	data.merge(.get_data())
	
	return data
