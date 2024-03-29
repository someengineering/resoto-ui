class_name AggregateSearchDataSource
extends DataSource

signal structure_received

var grouping_variables := ""
var grouping_functions := ""
var search_query := ""
var query_structure := {}

func _init():
	type = TYPES.AGGREGATE_SEARCH
	

func update_query():
	query = 'aggregate(%s: %s): %s' % [grouping_variables, grouping_functions, search_query]


func make_query(dashboard_filters : Dictionary, _attr : Dictionary):
	var q : String = query

	if dashboard_filters["cloud"] != "" and dashboard_filters["cloud"] != "All":
		q += " and /ancestors.cloud.reported.name=\"%s\"" % dashboard_filters["cloud"]
	if dashboard_filters["region"] != "" and dashboard_filters["region"] != "All":
		q += " and /ancestors.region.reported.name=\"%s\"" % dashboard_filters["region"]
	if dashboard_filters["account"] != "" and dashboard_filters["account"] != "All":
		q += " and /ancestors.account.reported.name=\"%s\"" % dashboard_filters["account"]
		
	API.get_search_structure(q, self)
	yield(self, "structure_received")
	set_request(API.aggregate_search(q, self))


func _on_get_search_structure_done(error : int, response : ResotoAPI.Response):
	if error == OK:
		query_structure = response.transformed.result
	emit_signal("structure_received")

func _on_aggregate_search_done(_error : int, response):
	if _error == ERR_PRINTER_ON_FIRE:
		emit_signal("query_status", _error, "Query canceled")
		return
	if _error:
		var error_detail := ""
		if response:
			error_detail = "\n\n" + response.body.get_string_from_utf8()
		emit_signal("query_status", FAILED, "Invalid Aggregate Search", "There is a problem with the aggregate search query.%s" % error_detail)
		return
	if not response.transformed.result is Array:
		var error_detail := ""
		if response:
			error_detail = "\n\n" + response.body.get_string_from_utf8()
		_g.emit_signal("add_toast", "Invalid Aggregate Search", "There is a problem with the aggregate search query.", 1, self)
		emit_signal("query_status", FAILED, "Invalid Aggregate Search", "There is a problem with the aggregate search query.%s" % error_detail)
		return
	if  response.transformed.result.size() == 0:
		emit_signal("query_status", FAILED, "Empty Aggregate Search Result", "This search returned an empty result.")
		return

	if "query_structure" in widget:
		widget.query_structure = query_structure
	widget.set_data(response.transformed.result, type)
	emit_signal("query_status", OK, "")


func copy_data_source(other : AggregateSearchDataSource):
	grouping_variables = other.grouping_variables
	grouping_functions = other.grouping_functions
	search_query = other.search_query
	query = other.query


func get_data() -> Dictionary:
	var data := {
		"grouping_variables" : grouping_variables,
		"grouping_functions" : grouping_functions,
		"search_query" : search_query
	}
	data.merge(.get_data())
	return data
