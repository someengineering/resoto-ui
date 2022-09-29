extends PanelContainer

const Function = preload("res://components/search_cards/elements/aggregate_function.tscn")
const Variable = preload("res://components/search_cards/elements/aggregate_variable.tscn")

signal update_string

export(NodePath) onready var aggregate_button = get_node(aggregate_button)
export(NodePath) onready var filter_panel = get_node(filter_panel)
export(NodePath) onready var search_cards = get_node(search_cards)

var aggregate:bool = false
var properties:Array = []
var kinds:Array = []

onready var functions = $FilterGroup/Content/Functions/Functions
onready var variables = $FilterGroup/Content/Variables/Variables

func _on_DeleteButton_pressed():
	aggregate = false
	hide()
	aggregate_button.show()
	update_string()


func build_string() -> String:
	if functions.get_child_count() == 0:
		return ""
	
	var ags:= "aggregate(%s)"
	
	var var_strings:PoolStringArray = []
	for v in variables.get_children():
		var_strings.append(v.build_string())
	
	var f_strings:PoolStringArray = []
	for f in functions.get_children():
		f_strings.append(f.build_string())
	
	var vars = ", ".join(var_strings)
	var functs = ", ".join(f_strings)
	
	if !var_strings.empty():
		return ags % [str(vars + ": " + functs)]
	else:
		return ags % [functs]


func update_string():
	emit_signal("update_string")


func _on_AddAggregation_pressed():
	aggregate = true
	show()
	aggregate_button.hide()
	update_aggregation()
	update_string()


func update_aggregation():
	if filter_panel.filter_elements.empty():
		return
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	properties = filter_panel.filter_elements[-1].get_group_properties()
	kinds = filter_panel.filter_elements[-1].get_group_kinds()
	_on_update_function()
	_on_update_variable()


func _on_AddFunction_pressed():
	var new_function = Function.instance()
	new_function.connect("update_function", self, "update_string")
	new_function.connect("tree_exited", self, "_on_update_function")
	functions.add_child(new_function)
	new_function.update_prop_items(kinds)
	update_string()


func _on_AddVariable_pressed():
	var new_variable = Variable.instance()
	new_variable.connect("update_variable", self, "update_string")
	new_variable.connect("tree_exited", self, "_on_update_variable")
	variables.add_child(new_variable)
	new_variable.update_prop_items(properties)
	update_string()


func _on_update_function():
	var number_props:Array = []
	for k in kinds:
		var k_props:Array = search_cards.properties(k, null, true)
		number_props.append_array(k_props)
	
	for c in functions.get_children():
		c.update_prop_items(number_props)
	update_string()


func _on_update_variable():
	for c in variables.get_children():
		c.update_prop_items(properties)
	update_string()


func _on_SearchCardBuilder_update_string():
	update_aggregation()
	_on_update_function()
