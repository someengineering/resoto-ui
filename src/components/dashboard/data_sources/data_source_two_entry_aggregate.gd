class_name TwoEntryAggregateDataSource
extends AggregateSearchDataSource

var category_1 : String = ""
var category_1_alias : String = ""
var category_2 : String = ""
var category_2_alias : String = ""
var function : String = ""
var function_alias : String = ""
var kind : String = ""


func _init():
	type = TYPES.TWO_ENTRIES_AGGREGATE


func copy_data_source(other):
	category_1 = other.category_1
	category_1_alias = other.category_1_alias
	category_2 = other.category_2
	category_2_alias = other.category_2_alias
	function = other.function
	function_alias = other.function_alias
	kind = other.kind
	query = other.query


func update_query():
	if "" in [category_1, category_2, function, kind]:
		return
		
	var x_axis : String = category_1
	if category_1_alias != "":
		x_axis += " as %s" % category_1_alias
		
	var y_axis : String = category_2
	if category_2_alias != "":
		y_axis += " as %s" % category_2_alias
		
	var fn : String = function
	if function_alias != "":
		fn += " as %s" % function_alias
		
	query = "aggregate(%s, %s: %s) : is(%s)" % [x_axis, y_axis, fn, kind]
	
	
func get_data() -> Dictionary:
	var data : Dictionary = {
		"category_1" : category_1,
		"category_1_alias" : category_1_alias,
		"category_2" : category_2,
		"category_2_alias" : category_2_alias,
		"function" : function,
		"function_alias" : function_alias,
		"kind" : kind
	}
	
	data.merge(.get_data())
	print(JSON.print(data,"\t"))
	return data
