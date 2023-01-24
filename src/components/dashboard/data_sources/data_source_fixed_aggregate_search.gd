class_name FixedAggregateSearch
extends AggregateSearchDataSource

var categories : PoolStringArray = ["/ancestors.cloud.reported.name as cloud", "/ancestors.region.reported.name as region"]
var function : String = ""
var function_alias : String = ""
var search : String = ""


func _init():
	type = TYPES.FIXED_AGGREGATE


func copy_data_source(other):
	categories = other.categories.duplicate()
	function = other.function
	function_alias = other.function_alias
	search = other.search
	query = other.query


func update_query():
	if "" in [function, search]:
		return
		
	var fn : String = function
	if function_alias != "":
		fn += " as %s" % function_alias
	
	var group : String = categories.join(", ")
	query = "aggregate(%s: %s) : %s" % [group, fn, search]
	
	
func get_data() -> Dictionary:
	var data : Dictionary = {
		"categories" : categories,
		"function" : function,
		"function_alias" : function_alias,
		"search" : search
	}
	
	data.merge(.get_data())
	return data
