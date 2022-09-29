extends PanelContainer

signal update_string

export(NodePath) onready var aggregate_button = get_node(aggregate_button)
export(NodePath) onready var filter_panel = get_node(filter_panel)

var aggregate:bool = false
var properties:Array = []

func _on_DeleteButton_pressed():
	aggregate = false
	hide()
	aggregate_button.show()
	update_string()


func update_string():
	emit_signal("update_string")


func _on_AddAggregation_pressed():
	aggregate = true
	show()
	aggregate_button.hide()
	update_aggregation()
	update_string()


func update_aggregation():
	properties = filter_panel.filter_elements[-1].get_group_properties()
	print(properties)
