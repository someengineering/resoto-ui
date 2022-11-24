extends GridContainer

signal filter_element_changed(filter)
signal filter_element_convert(filter)

onready var labels := $LabelsComboBox
onready var operators := $OperatorsComboBox
onready var value := $ValueComboBox

var filter_value := ""
var filter_label := ""
var filter_operator := ""
var filter_dict := {"filter_type" : "combo", "content" : {"label": "", "operator": "", "value": ""}}


func _ready():
	labels.items = []
	value.items = []


func get_filter() -> String:
	return "%s%s\"%s\"" % [filter_dict.content.label, filter_dict.content.operator, filter_dict.content.value]


func set_filter_values(_label:String, _operator:String, _value:String):
	filter_label = _label
	filter_operator = _operator
	filter_value = _value
	filter_dict.content.label = filter_label
	filter_dict.content.operator = filter_operator
	filter_dict.content.value = filter_value
	labels.text = filter_label
	operators.text = filter_operator
	value.text = filter_value


func _on_tsdb_label_values_done(_error:int, response):
	if _error:
		return
	var data = response.transformed.result
	if typeof(data) != TYPE_DICTIONARY:
		_g.emit_signal("add_toast", "No labels found", "Couldn't find labels for this filters.", 2, self)
		return
	var array := []
	for item in data.data:
		array.append(item)
	value.set_items(array)


func set_label_box(_values:Array):
	labels.set_items(_values)


func set_values_box(_values:Array):
	value.set_items(_values)


func update_filter():
	filter_dict.content.label = filter_label
	filter_dict.content.operator = filter_operator
	filter_dict.content.value = filter_value
	if filter_label != "" and filter_operator != "" and filter_value != "":
		emit_signal("filter_element_changed")


func _on_LabelsComboBox_option_changed(option):
	API.tsdb_label_values(option, self)
	filter_label = option
	update_filter()


func _on_DeleteFilterButton_pressed():
	queue_free()


func _on_ValueComboBox_option_changed(option):
	filter_value = option
	update_filter()


func _on_ValueComboBox_text_changed(text):
	filter_value = text
	update_filter()


func _on_OperatorsComboBox_text_changed(text):
	filter_operator = text
	update_filter()


func _on_OperatorsComboBox_option_changed(option):
	filter_operator = option
	update_filter()


func _on_ConvertButton_pressed():
	var filter = get_filter()
	if filter == "\"\"":
		filter = ""
	emit_signal("filter_element_convert", filter, get_position_in_parent())
	queue_free()
