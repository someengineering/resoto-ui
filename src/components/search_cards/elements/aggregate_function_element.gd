extends HBoxContainer

signal update_function

var parent:SearchCards
var function_type:= 0
var properties:= []

var function_data:Dictionary = {
	0: ["count elements", "sum(1)"],
	1: ["sum", "sum(%s)"],
	2: ["min", "min(%s)"],
	3: ["max", "max(%s)"],
	4: ["avg", "avg(%s)"],
}


func update_prop_items(props:Array):
	properties = props
	
	var f_vars = $FunctionVariable
	f_vars.clear()
	for p in properties:
		f_vars.add_item(p)


func _on_FunctionType_item_selected(index):
	function_type = index
	var selected_count = function_type == 0
	$FunctionType.size_flags_horizontal = 3 if selected_count else 0
	$FunctionVariable.visible = !selected_count
	emit_signal("update_function")


func build_string():
	if function_type > 0 and $FunctionVariable.get_item_count() == 0:
		return ""
	var function_string:String = function_data[function_type][1]
	if function_type > 0:
		var prop_index:int = $FunctionVariable.selected
		var property_name:String = $FunctionVariable.items[prop_index]
		function_string = function_string % [property_name]
	if $LineEdit.text != "":
		function_string += " as " + $LineEdit.text
	return function_string


func _on_FunctionDeleteButton_pressed():
	queue_free()


func _on_LineEdit_text_changed(new_text):
	emit_signal("update_function")


func _on_FunctionVariable_item_selected(index):
	emit_signal("update_function")
