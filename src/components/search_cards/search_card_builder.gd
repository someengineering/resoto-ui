extends VBoxContainer

export(NodePath) onready var main = get_node(main)

var FilterGroupPanel = preload("res://components/search_cards/elements/cards_filtergroup_panel.tscn")
var NavigationPanel = preload("res://components/search_cards/elements/cards_navigation_panel.tscn")

var filter_elements:Array = []
var nav_elements:Array = []

onready var elements = $Elements

func _ready():
	_on_AddGroupLayer_pressed()


func _on_AddGroupLayer_pressed():
	var next_child = null
	if nav_elements.size() < filter_elements.size():
		next_child = NavigationPanel.instance()
		next_child.connect("delete", self, "_on_NavigationPanel_delete", [next_child])
		nav_elements.append(next_child)
	else:
		next_child = FilterGroupPanel.instance()
		next_child.main = main
		next_child.connect("delete", self, "_on_FilterGroupPanel_delete", [next_child])
		filter_elements.append(next_child)
	elements.add_child(next_child)
	next_child.connect("update_string", self, "build_string")
	build_string()
	

func build_string():
	var query_string:= ""
	for c in elements.get_children():
		query_string += c.query_string + " "
	print(query_string)


func _on_FilterGroupPanel_delete(panel:Node):
	var filter_index = filter_elements.find(panel)
	if nav_elements.size() >= filter_index+1:
		_on_NavigationPanel_delete(nav_elements[filter_index])
	
	filter_elements.erase(panel)
	panel.queue_free()


func _on_NavigationPanel_delete(panel:Node):
	var nav_index = nav_elements.find(panel)
	if filter_elements.size() > nav_index+1:
		_on_FilterGroupPanel_delete(filter_elements[nav_index+1])
	
	nav_elements.erase(panel)
	panel.queue_free()
