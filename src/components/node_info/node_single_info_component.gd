extends ComponentContainer


func apply_navigation_arguments():
	if "node_id" in navigation_arguments:
		component.show_node(navigation_arguments["node_id"], false)
		update_title()


func _on_NodeSingleInfo_node_shown(node_id):
	update_navigation_arguments({"node_id": node_id})
	update_title()


func update_title():
	var node_name : String = component.get_node("%NodeNameLabel").text
	var kind_label : String = component.get_node("%KindLabelButton").text
	UINavigation.change_title("Explore: %s - %s" % [node_name, kind_label])
