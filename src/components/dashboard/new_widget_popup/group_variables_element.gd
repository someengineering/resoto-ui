extends GridContainer

signal element_changed

var element_name := "Grouping Variable"

# Just for loading templates
var variable : String = "" setget set_variable
var alias : String = "" setget set_alias

onready var group_variable_line_edit := $GroupingVariableLineEdit
onready var alias_line_edit := $AliasLineEdit

func _ready():
	$Label.text = element_name

func get_grouping_variable() -> String:
	var group_variable : String = group_variable_line_edit.text
	if alias_line_edit.text != "":
		group_variable += " as %s" % alias_line_edit.text
		
	return group_variable

func _on_DeleteFilterButton_pressed():
	queue_free()


func _on_GroupingVariableLineEdit_text_entered(_new_text):
	emit_signal("element_changed")


func _on_AliasLineEdit_text_entered(_new_text):
	emit_signal("element_changed")


func set_variable(_variable : String):
	variable = _variable
	group_variable_line_edit.text = variable
	emit_signal("element_changed")


func set_alias(_alias : String):
	alias = _alias
	alias_line_edit.text = alias
	emit_signal("element_changed")
