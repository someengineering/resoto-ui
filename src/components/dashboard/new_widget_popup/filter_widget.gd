extends Control

signal filter_changed(filters, filter_dicts)

const FilterElement = preload("res://components/dashboard/new_widget_popup/filter_widget_element.tscn")
const FilterTextElement = preload("res://components/dashboard/new_widget_popup/filter_widget_text_element.tscn")

var filters := "" setget set_filters
var labels := []
var values := []
var filter_dicts := [] setget set_filter_dicts

onready var filter_container := $VBoxContainer/Margin/FilterContainer


func set_filters(_filters:String):
	filters = _filters


func set_filter_dicts(_filter_dicts:Array):
	if _filter_dicts.empty():
		return
	filter_dicts = _filter_dicts.duplicate()
	for elem in _filter_dicts:
		if elem.filter_type == "combo":
			filter_element(elem.content)
			
		elif elem.filter_type == "text":
			filter_element_convert(elem.content.text)


func update_filter() -> void:
	var collected_filters : PoolStringArray = []
	filter_dicts.clear()
	for c in filter_container.get_children():
		collected_filters.append(c.get_filter())
		filter_dicts.append(c.filter_dict)
	filters = collected_filters.join(", ")
	$UpdateDelay.start()


func set_labels(_labels:Array):
	labels = _labels
	for _filter in filter_container.get_children():
		if _filter.has_method("set_label_box"):
			_filter.set_label_box(labels)


func set_values(_values:Array):
	values = _values
	for _filter in filter_container.get_children():
		if _filter.has_method("set_values_box"):
			_filter.set_values_box(values)


func filter_element_convert(_filter:String, _pos_in_parent:=0):
	var new_text_filter = FilterTextElement.instance()
	filter_container.add_child(new_text_filter)
	new_text_filter.filter = _filter
	new_text_filter.connect("tree_exited", self, "update_filter")
	new_text_filter.connect("filter_element_changed", self, "update_filter")
	filter_container.move_child(new_text_filter, _pos_in_parent)


func filter_element(_dict:= {}):
	var new_filter = FilterElement.instance()
	filter_container.add_child(new_filter)
	new_filter.set_label_box(labels)
	new_filter.set_values_box(values)
	new_filter.connect("tree_exited", self, "update_filter")
	new_filter.connect("filter_element_changed", self, "update_filter")
	new_filter.connect("filter_element_convert", self, "filter_element_convert")
	if not _dict.empty():
		new_filter.set_filter_values(_dict.label, _dict.operator, _dict.value)


func _on_AddFilterButton_pressed():
	filter_element()


func _on_UpdateDelay_timeout():
	emit_signal("filter_changed", filters, filter_dicts)
