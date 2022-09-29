extends PanelContainer

signal delete
signal update_string

var main:Node = null setget set_main
var sort_limit_string:= " limit 20"


func set_main(_main):
	main = _main
	$FilterGroup.main = main


func get_group_properties():
	return $FilterGroup/SortLimitBar.properties


func get_group_kinds():
	var elements = $FilterGroup.active_filters
	var kinds:= []
	for e in elements:
		kinds.append(e.kind)
	return kinds


func _on_DeleteButton_pressed():
	emit_signal("delete")


func build_string():
	return $FilterGroup.build_string() + sort_limit_string


func _on_FilterGroup_update_string():
	show_sort_limit_bar($FilterGroup.active_filters.empty())
	emit_signal("update_string")


func show_sort_limit_bar(value:bool):
	$FilterGroup/SortLimitBar.visible = !value
	$FilterGroup/SortLimitSpacer.visible = value


func _on_SortLimitBar_update_sort_limit(_sort_limit_string):
	sort_limit_string = _sort_limit_string
	emit_signal("update_string")
