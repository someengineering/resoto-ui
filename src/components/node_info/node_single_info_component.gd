extends ComponentContainer


func apply_navigation_arguments():
	if "node_id" in navigation_arguments:
		component.show_node(navigation_arguments["node_id"], false)


func _on_NodeSingleInfo_node_shown(node_id):
	update_navigation_arguments({"node_id": node_id})
