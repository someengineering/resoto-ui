extends ComponentContainer


func apply_navigation_arguments():
	if "query" in navigation_arguments:
		component.show_aggregation(navigation_arguments["query"].percent_decode(), false)


func _on_AggregationViewComponent_visibility_changed():
	if not visible:
		update_navigation_arguments({"query": component.edit.text.percent_encode()})
