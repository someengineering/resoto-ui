class_name DataSource
extends Node

signal query_status

enum TYPES {TIME_SERIES, AGGREGATE_SEARCH, SEARCH, TWO_ENTRIES_AGGREGATE}

var query : String
var widget 
var type : int = TYPES.TIME_SERIES
var _request : UserAgent.Request = null
var custom_query : bool = false


func _init():
	self.connect("query_status", self, "_on_query_status")

func make_query(_dashboard_filters : Dictionary, _attr : Dictionary):
	pass
	
func copy_data_source(_other):
	pass
	
func update_query():
	pass
	
func get_data() -> Dictionary:
	var data = {
		"type" : type,
		"query" : query,
		"custom_query" : custom_query
	}
	return data

func _on_query_status(_type:int=0, _title:="Widget Error", _message:=""):
	var properties := {
		"datasource_type" : TYPES.keys()[type],
		"message" : _message,
		"title" : _title
	}
	if _type != OK:
		Analytics.event(Analytics.EventsDatasource.FAILED, properties)
		
func set_request(new_request : UserAgent.Request):
	if is_instance_valid(_request) and _request != null:
		_request.cancel()
		
	_request = new_request


func is_executing_query() -> bool:
	if _request == null:
		return false
	
	return _request.state_ == UserAgent.Request.states.DONE
