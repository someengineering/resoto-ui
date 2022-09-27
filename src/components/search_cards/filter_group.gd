extends VBoxContainer

var FilterElement = preload("res://components/search_cards/elements/card_filter_element.tscn")

var active_filters:= []

onready var filter_group_container = $FilterContainer
onready var add_button = $FilterContainer/AddFilterElementButton

func _on_AddFilterElementButton_pressed():
	var new_filter = FilterElement.instance()
	active_filters.append(new_filter)
	new_filter.connect("delete", self, "on_filter_delete", [new_filter])
	filter_group_container.add_child(new_filter)#	new_filter.connect()
	filter_group_container.move_child(add_button, filter_group_container.get_child_count())


func on_filter_delete(_element:Node):
	active_filters.erase(_element)
	_element.queue_free()
