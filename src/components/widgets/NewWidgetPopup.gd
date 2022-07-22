extends WindowDialog

signal widget_added(widget_data)

var current_widget_preview_name : String = "Indicator"
var current_wdiget_properties : Dictionary = {}
var preview_widget : BaseWidget = null
var data_sources : Array = []
var metrics : Dictionary = {}

var widget_to_edit = null

var from_date : int
var to_date : int
var interval : int

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

func _ready() -> void:
	for key in widgets:
		widget_type_options.add_item(key)

func _on_AddWidgetButton_pressed() -> void:
	var widget = widgets[widget_type_options.text].instance() if widget_to_edit == null else widget_to_edit.widget
	var properties = get_preview_widget_properties()
	
	for key in get_preview_widget_properties():
		widget[key] = properties[key]
		
	var new_data_sources : Array = []

	for datasource in data_source_container.get_children():
		var ds = datasource.data_source.duplicate()
		ds.copy_data_source(datasource.data_source)
		ds.widget = widget
		new_data_sources.append(ds)
		
	if widget_to_edit == null:
		var widget_data := {
			"scene" : widget,
			"title" : widget_name_label.text,
			"data_sources" : new_data_sources
		}
		emit_signal("widget_added", widget_data)
	else:
		widget_to_edit.title = widget_name_label.text
		widget_to_edit.data_sources.clear()
		widget_to_edit.data_sources = new_data_sources
		widget_to_edit = null
	
	
	hide()
	preview_widget.queue_free()


func _on_WidgetType_item_selected(_index : int) -> void:
	if widget_type_options.text == current_widget_preview_name:
		return
	create_preview(widget_type_options.text)
	
func create_preview(widget_type : String = "Indicator") -> void:
	if is_instance_valid(preview_widget):
		preview_widget.queue_free()
	
	if widget_to_edit == null:
		preview_widget = widgets[widget_type].instance()
	else:
		preview_widget = load(widget_to_edit.widget.filename).instance()
		for key in get_preview_widget_properties():
			preview_widget[key] = widget_to_edit.widget[key]
		
	preview_widget.size_flags_vertical = SIZE_EXPAND_FILL
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
		


func get_control_for_property(property : Dictionary) -> Control:
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
	
func get_preview_widget_properties() -> Dictionary:
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

func _on_NameEdit_text_changed(new_text : String) -> void:
	if preview_container.get_child_count() > 0:
		$WidgetPreview/VBoxContainer/VBoxContainer/PreviewContainer/PanelContainer/Title.text = new_text


func _on_get_config_id_done(_error, _response, _config_key) -> void:
	metrics =  _response.transformed.result["resotometrics"]["metrics"]


func _on_NewWidgetPopup_about_to_show() -> void:
	for data_source in data_source_container.get_children():
		data_source.queue_free()
	if widget_to_edit != null:
		for data_source in widget_to_edit.data_sources:
			var ds = data_source_widget.instance()
			data_source_container.add_child(ds)
			ds.connect("source_changed", self, "update_preview")
			ds.data_source = data_source
			
	$WidgetOptions/VBoxContainer/VBoxContainer2.visible = widget_to_edit == null
	create_preview(current_widget_preview_name)
	API.get_config_id(self, "resoto.metrics")
	print("show")


func _on_AddDataSource_pressed() -> void:
	var ds = data_source_widget.instance()
	ds.interval = interval
	
	data_source_container.add_child(ds)
	ds.widget = preview_widget
	ds.connect("source_changed", self, "update_preview")
	ds.connect("tree_exited", self, "update_preview")
	ds.set_metrics(metrics)
	
	
func update_preview() -> void:
	if not is_instance_valid(preview_widget):
		return
		
	if preview_widget.has_method("clear_series"):
		preview_widget.clear_series()
		
	for datasource in data_source_container.get_children():
		datasource.data_source.make_query(from_date, to_date, interval)

func edit_widget(widget) -> void:
	widget_to_edit = widget
	popup_centered()
	
