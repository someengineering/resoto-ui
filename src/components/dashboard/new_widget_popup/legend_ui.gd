extends PanelContainer

signal legend_changed(new_legend)
signal stack_changed(new_stack)

var index : int = 0 setget set_index
var text : String = "" setget set_text
var stack : bool = true setget set_stack

var last_metric_keys : Array = []

onready var legend_help := $VBoxContainer/GridContainer/LegendTitle/LegendHelp

func set_index(new_index : int):
	index = new_index
	$VBoxContainer/Label.text = "Data Source %d options" % [index + 1]


func _on_LegendEdit_text_entered(new_text):
	text = new_text
	emit_signal("legend_changed", text)


func set_text(new_text : String):
	text = new_text
	$VBoxContainer/GridContainer/LegendEdit.text = text


func set_stack(_stack : bool):
	stack = _stack
	$VBoxContainer/GridContainer/StackCheckButton.pressed = _stack


func _on_StackCheckButton_toggled(button_pressed):
	stack = button_pressed
	emit_signal("stack_changed", stack)


func update_legend_help(_last_metric_keys : Array):
	last_metric_keys = _last_metric_keys
	var help_text_legend := "[b]Set the legend on the widget.[/b]\nIf the result contains labels, you can display them by wrapping it in curly braces.\n"
	help_text_legend += "[b]Examples[/b]\n- [code]{label_name}[/code]\n- [code]Cloud: {cloud}[/code]%s"
	if not last_metric_keys.empty():
		var last_metric_string : PoolStringArray = []
		for key in last_metric_keys:
			last_metric_string.append("[code]{%s}[/code]" % key)
		help_text_legend = help_text_legend % str("\n\nThe last query returned the following labels:\n[code]%s[/code]" % last_metric_string.join(", "))
	else:
		help_text_legend = help_text_legend % ""
	legend_help.tooltip_text = help_text_legend
