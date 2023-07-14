extends ComponentContainer


func apply_navigation_arguments():
	if "node_id" in navigation_arguments:
		var tab = navigation_arguments["tab"] if "tab" in navigation_arguments else "last"
		component.show_node(navigation_arguments["node_id"], false, tab)
		update_title()


func _on_NodeSingleInfo_node_shown(node_id, tab):
	update_navigation_arguments({"node_id": node_id, "tab": tab})
	update_title()


func update_title():
	var node_name : String = component.get_node("%NodeNameLabel").text
	var kind_label : String = component.get_node("%KindLabelButton").text
	UINavigation.change_title("Explore: %s - %s" % [node_name, kind_label])
