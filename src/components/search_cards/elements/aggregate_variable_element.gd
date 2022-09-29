extends HBoxContainer

signal update_variable

var parent:SearchCards
var properties:= []
var selected_index:int= 0

onready var text_field = $VariableName


func update_prop_items(props:Array):
	properties = props
	text_field.clear()
	for p in properties:
		text_field.add_item(p)


func build_string():
	var sel_i = text_field.get_selected_id()
	var variable_string:String = text_field.items[selected_index].name
	if $LineEdit.text != "":
		variable_string += " as " + $LineEdit.text
	return variable_string


func _on_VariableName_item_selected(index):
	selected_index = index
	text_field.select(index)
	emit_signal("update_variable")


func _on_VariableDeleteButton_pressed():
	queue_free()


func _on_LineEdit_text_changed(new_text):
	emit_signal("update_variable")
