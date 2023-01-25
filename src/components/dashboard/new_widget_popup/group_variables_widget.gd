extends PanelContainer

signal group_variables_changed(grouping_variables)

const GroupVariablesElement := preload("res://components/dashboard/new_widget_popup/group_variables_element.tscn")

export (String) var title := "Grouping Variables" setget set_title
export (String) var element_name := "Grouping Variable"

var grouping_variables := ""

onready var variables_container := $VBoxContainer/Margin/VariablesContainer
onready var update_delay := $UpdateDelay


func _ready():
	set_title(title)


func _on_AddVariableButton_pressed():
	var variable := GroupVariablesElement.instance()
	variable.connect("element_changed", self, "update_grouping_variables")
	variable.connect("tree_exited", self, "update_grouping_variables")
	variable.element_name = element_name
	variables_container.add_child(variable)


func update_grouping_variables():
	var grouping_variables_array : PoolStringArray = []
	for element in variables_container.get_children():
		grouping_variables_array.append(element.get_grouping_variable())
		
	grouping_variables = grouping_variables_array.join(", ")
	update_delay.start()


func _on_UpdateDelay_timeout():
	emit_signal("group_variables_changed", grouping_variables)
	
func set_title(_title : String):
	title = _title
	if not is_inside_tree():
		return
	$VBoxContainer/Headline/Label.text = title


func _on_group_variables_widget_tree_exiting():
	for variable in variables_container.get_children():
		variable.disconnect("tree_exited", self, "update_grouping_variables")
