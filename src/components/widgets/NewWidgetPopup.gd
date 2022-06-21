extends WindowDialog

signal widget_added(widget_data)

var current_widget_preview_name : String = "Indicator"
var preview_widget : Control = null

const widgets := {
	"Indicator" : preload("res://components/widgets/Indicator.tscn")
}

onready var widget_type_options := find_node("WidgetType")
onready var preview_container := find_node("PreviewContainer")
onready var widget_name_label := find_node("NameEdit")
onready var options_container := find_node("Options")

func _ready():
	for key in widgets:
		widget_type_options.add_item(key)
	create_preview(current_widget_preview_name)

func _on_AddWidgetButton_pressed():
	var widget_data := {
		"scene" : preview_widget.duplicate(),
		"title" : widget_name_label.text
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
