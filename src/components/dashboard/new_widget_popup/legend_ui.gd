extends HBoxContainer

signal legend_changed(new_legend)

var index : int = 0 setget set_index
var text : String = "" setget set_text


func set_index(new_index : int):
	index = new_index
	$LegendTitle/LegendLabel.text = "Legend %d" % [index + 1]


func _on_LegendEdit_text_entered(new_text):
	text = new_text
	emit_signal("legend_changed", text)


func set_text(new_text : String):
	text = new_text
	$LegendEdit.text = text
