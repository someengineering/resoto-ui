extends WindowDialog

signal widget_added(widget_data)

var current_widget_preview_name : String = "Indicator"
var current_wdiget_properties : Dictionary = {}
var preview_widget : BaseWidget = null
var data_sources : Array = []
var metrics : Dictionary = {}

var data_source_widget := preload("res://components/widgets/DatasourceContainer.tscn")

var query : String = ""

onready var data_source_container := find_node("DataSources")

const widgets := {
	"Indicator" : preload("res://components/widgets/Indicator.tscn"),
	"Chart" : preload("res://components/widgets/Chart.tscn")
}

onready var widget_type_options := find_node("WidgetType")
onready var preview_container := find_node("PreviewContainer")
onready var widget_name_label := find_node("NameEdit")
onready var options_container := find_node("Options")

func _ready():
	for key in widgets:
		widget_type_options.add_item(key)

func _on_AddWidgetButton_pressed():
	var widget = widgets[widget_type_options.text].instance()
	var properties = get_preview_widget_properties()
	for key in get_preview_widget_properties():
		widget[key] = properties[key]
	var data_sources : Array = []

	for datasource in data_source_container.get_children():
		var ds = datasource.data_source.duplicate()
		ds.query = datasource.data_source.query
		ds.legend = datasource.data_source.legend
		ds.widget = widget
		ds.stacked = datasource.data_source.stacked
		data_sources.append(ds)
		
	var widget_data := {
		"scene" : widget,
		"title" : widget_name_label.text,
		"data_sources" : data_sources
	}
	emit_signal("widget_added", widget_data)
	
	
	hide()


func _on_WidgetType_item_selected(_index):
	if widget_type_options.text == current_widget_preview_name:
		return
	create_preview(widget_type_options.text)
	
func create_preview(widget_type : String = "Indicator") -> void:
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
	
	for datasource in data_source_container.get_children():
		datasource.widget = preview_widget

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


func _on_get_config_id_done(_error, _response, config_key) -> void:
	metrics =  _response.transformed.result["resotometrics"]["metrics"]


func _on_NewWidgetPopup_about_to_show():
	create_preview(current_widget_preview_name)
	for data_source in data_source_container.get_children():
		data_source.queue_free()
	API.get_config_id(self, "resoto.metrics")


func _on_AddDataSource_pressed():
	var ds = data_source_widget.instance()
	data_source_container.add_child(ds)
	ds.widget = preview_widget
	ds.connect("source_changed", self, "update_preview")
	ds.connect("tree_exited", self, "update_preview")
	ds.set_metrics(metrics)
	
	
func update_preview():
	if preview_widget.has_method("clear_series"):
		print("cleared")
		preview_widget.clear_series()
	for datasource in data_source_container.get_children():
		datasource.data_source.make_query()
