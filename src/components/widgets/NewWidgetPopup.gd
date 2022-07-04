extends WindowDialog

signal widget_added(widget_data)

var current_widget_preview_name : String = "Indicator"
var current_wdiget_properties : Dictionary = {}
var preview_widget : Control = null


var query : String = ""

onready var metrics_options := find_node("MetricsOptions")
onready var filters_widget := find_node("FilterWidget")

const widgets := {
	"Indicator" : preload("res://components/widgets/Indicator.tscn")
}

onready var widget_type_options := find_node("WidgetType")
onready var preview_container := find_node("PreviewContainer")
onready var widget_name_label := find_node("NameEdit")
onready var options_container := find_node("Options")
onready var function_options := find_node("FunctionOptions")

func _ready():
	for key in widgets:
		widget_type_options.add_item(key)
	create_preview(current_widget_preview_name)

func _on_AddWidgetButton_pressed():
	var widget = widgets[widget_type_options.text].instance()
	var properties = get_preview_widget_properties()
	for key in get_preview_widget_properties():
		widget[key] = properties[key]
	var widget_data := {
		"scene" : widget,
		"title" : widget_name_label.text,
		"query" : query
	}
	emit_signal("widget_added", widget_data)
	
	hide()


func _on_WidgetType_item_selected(_index):
	if widget_type_options.text == current_widget_preview_name:
		return
	create_preview(widget_type_options.text)
	
func create_preview(widget_type : String) -> void:
	if is_instance_valid(preview_widget):
		preview_widget.queue_free()
		
	preview_widget = widgets[widget_type].instance()
	
	for option in options_container.get_children():
		option.queue_free()
	
	# create properties options
	var found_settings := false
	for property in preview_widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			var label = Label.new()
			label.text = property.name
			var value = get_control_for_property(property)
			options_container.add_child(label)
			options_container.add_child(value)
			
			value.size_flags_horizontal |= SIZE_EXPAND
		elif property.name == "Widget Settings":
			 found_settings = true
			
	preview_container.add_child(preview_widget)
	current_widget_preview_name = widget_type

func get_control_for_property(property : Dictionary):
	var control : Control
	var control_signal := ""
	
	match property.type:
		TYPE_INT:
			control = SpinBox.new()
			control.value = preview_widget[property.name]
			control_signal = "value_changed"
		TYPE_STRING:
			control = LineEdit.new()
			control.text = preview_widget[property.name]
			control_signal = "text_changed"
		TYPE_COLOR:
			control = ColorPickerButton.new()
			control.color = preview_widget[property.name]
			control_signal = "color_changed"
	
	control.connect(control_signal, preview_widget, "set_"+property.name)
	control.size_flags_horizontal |= SIZE_EXPAND
			
	return control
	
func get_preview_widget_properties():
	var found_settings := false
	var properties := {}
	for property in preview_widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			properties[property.name] = preview_widget[property.name]
		elif property.name == "Widget Settings":
			 found_settings = true
			
	return properties

func _on_NameEdit_text_changed(new_text):
	if preview_container.get_child_count() > 0:
		preview_container.get_child(0).variable_name = new_text


func _on_SuffixLabel_text_changed(new_text):
	if preview_container.get_child_count() > 0:
		preview_container.get_child(0).unit = new_text


func _on_get_config_id_done(_error, _response, config_key) -> void:
	for metric in _response.transformed.result["resotometrics"]["metrics"]:
		metrics_options.add_item(metric)


func _on_NewWidgetPopup_about_to_show():
	metrics_options.clear()
	API.get_config_id(self, "resoto.metrics")


func _on_MetricsOptions_item_selected(_index):
	update_preview()
	
func update_preview():
	if is_instance_valid(preview_widget):
		query = function_options.text+"(resoto_"+metrics_options.text + "{%s})"
		var filters : String = filters_widget.get_node("VBoxContainer/LineEdit").text
		query = query % filters
		print(query)
		API.query_tsdb(query, self)
		
func _on_query_tsdb_done(_error:int, response):
	var data = response.transformed.result
	var labels := []
	if data.data.result.size() == 0:
		_g.emit_signal("add_toast", "Empty result", "Your time series query returned an empty result...", 1)
		return
	for label in data.data.result[0].metric:
		if not label.begins_with("__"):
			labels.append(label)
			
	filters_widget.labels.set_items(labels)
	if data["status"] == "success":
		if data["data"]["result"].size() > 0:
			preview_widget.value = data["data"]["result"][0]["value"][1]
	else:
		_g.emit_signal("add_toast", "TSDB Query Error %s" % data["errorType"], data["error"],1)
		preview_widget.value = "NaN"

func _on_FunctionOptions_item_selected(index):
	update_preview()


func _on_AccountOptions_item_selected(index):
	update_preview()


func _on_RegionOptions_item_selected(index):
	update_preview()


func _on_FilterWidget_filter_changed(_filter):
	update_preview()
