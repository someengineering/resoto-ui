class_name DataSource
extends Node

signal query_status
signal query_success

enum TYPES {TIME_SERIES, AGGREGATE_SEARCH, SEARCH}

var query : String
var widget 
var type : int = TYPES.TIME_SERIES

func make_query(dashboard_filters : Dictionary, attr : Dictionary):
	pass
	
func copy_data_source(other):
	pass
	
func update_query():
	pass
	
func get_data() -> Dictionary:
	var data = {
		"type" : type,
		"query" : query
	}
	return data
