extends WindowDialog

signal widget_added(widget_data)

var current_widget_preview_name : String = "Indicator"
var preview_widget : Control = null

var cloud_filters : Array = []
var account_filters : Array = []
var region_filters : Array = []
var query : String = ""

onready var metrics_options := find_node("MetricsOptions")
onready var cloud_options := find_node("CloudOptions")
onready var account_options := find_node("AccountOptions")
onready var region_options := find_node("RegionOptions")

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
	var widget_data := {
		"scene" : preview_widget.duplicate(),
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
	cloud_filters.clear()
	region_filters.clear()
	cloud_options.clear()
	cloud_options.add_item("All")
	API.get_config_id(self, "resoto.metrics")
	
	for info in API.infra_info:
		if "reported" in info:
			if info.reported.kind == "cloud":
				cloud_filters.append(info.reported.name)
				cloud_options.add_item(info.reported.name)
			if "account" in info.reported.kind:
				account_filters.append({
					"name":info.reported.name,
					"cloud":info.ancestors.cloud.reported.name
				})
			if "region" in info.reported.kind:
				region_filters.append({
					"name":info.reported.name,
					"cloud":info.ancestors.cloud.reported.name
				})
	_on_CloudOptions_item_selected(cloud_options.selected)
	
	


func _on_CloudOptions_item_selected(_index):
	var text = cloud_options.text
	account_options.clear()
	account_options.add_item("All")
	for account in account_filters:
		if text == "*" or text == account.cloud:
			account_options.add_item(account.name)
			
	region_options.clear()
	region_options.add_item("All")
	for region in region_filters:
		if text == "All" or text == region.cloud:
			region_options.add_item(region.name)
			
	update_preview()


func _on_MetricsOptions_item_selected(_index):
	update_preview()
	
func update_preview():
	if is_instance_valid(preview_widget):
		query = function_options.text+"(resoto_"+metrics_options.text + "{%s})"
		var filters : String = ""
		if cloud_options.text != "All":
			filters+='cloud="%s"' % cloud_options.text
		if region_options.text != "All":
			filters+=', region="%s"' % region_options.text
		if account_options.text != "All":
			filters+=', account="%s"' % account_options.text
			
		query = query % filters
		print(query)
		API.query_tsdb(query, self)
		
func _on_query_tsdb_done(_error:int, response):
	var data = response.transformed.result
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
