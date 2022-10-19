class_name DataSource
extends Node

signal query_status

enum TYPES {TIME_SERIES, AGGREGATE_SEARCH, SEARCH}

var query : String
var widget 
var type : int = TYPES.TIME_SERIES


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
		"query" : query
	}
	return data

func _on_query_status(_type:int=0, _title:="Widget Error", _message:=""):
	var properties := {
		"type" : TYPES.keys()[type],
		"message" : _message,
		"title" : _title
	}
	if _type != OK:
		Analytics.event(Analytics.EventsDatasource.FAILED, {"datasource_type" : TYPES.keys()[type], "message" : _message})
