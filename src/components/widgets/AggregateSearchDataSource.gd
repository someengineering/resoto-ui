class_name AggregateSearchDataSource
extends DataSource

func _init():
	type = TYPES.AGGREGATE_SEARCH
	
func make_query(dashboard_filters : Dictionary, attr : Dictionary):
	API.aggregate_search(query, self)
	
func _on_aggregate_search_done(_error : int, response):
	if widget is TableWidget:
		widget.header_columns_count = response.transformed.result[0]["group"].size()
		print(widget.header_columns_count)
	widget.set_data(response.transformed.result)

	
func copy_data_source(other : AggregateSearchDataSource):
	query = other.query
	

