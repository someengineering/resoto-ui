extends VBoxContainer

signal update_string
signal update_elements

var FilterElement = preload("res://components/search_cards/elements/card_filter_element.tscn")
var OperatorButton = preload("res://components/search_cards/elements/cards_operator_button.tscn")

var main:Node = null
var active_filters:= {}

onready var filter_group_container = $FilterContainer
onready var add_button = $FilterContainer/AddFilterElementButton


func _on_AddFilterElementButton_pressed():
	var new_filter = FilterElement.instance()
	active_filters[new_filter] = {"card": new_filter, "operator": null}
	new_filter.main = main
	new_filter.connect("delete", self, "on_filter_delete", [new_filter])
	new_filter.connect("update_string", self, "_on_update_string")
	new_filter.connect("update_properties", self, "_on_update_properties")
	if active_filters.size() > 1 and active_filters[new_filter].operator == null:
		var new_operator = OperatorButton.instance()
		new_operator.connect("update_string", self, "_on_update_string")
		active_filters[new_filter].operator = new_operator
		filter_group_container.add_child(new_operator)
	filter_group_container.add_child(new_filter)
	filter_group_container.move_child(add_button, filter_group_container.get_child_count())


func _on_update_properties():
	emit_signal("update_elements", active_filters.keys())


func on_filter_delete(_element:Node):
	var elem = active_filters[_element]
	if elem.operator != null:
		elem.operator.queue_free()
	elem.card.queue_free()
	active_filters.erase(_element)
	emit_signal("update_string")


func _on_update_string():
	emit_signal("update_string")


func build_string():
	var search_string:String = ""
	for c in filter_group_container.get_children():
		if c == add_button:
			continue
		search_string += c.build_string()
	return search_string
