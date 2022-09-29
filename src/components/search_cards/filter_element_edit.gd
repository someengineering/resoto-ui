extends Control

signal delete
signal update_string

var main:SearchCards = null
var kind:String = ""

onready var delete_button = find_node("DeleteButton")
onready var combo_box = $FilterEditElement/ComboBox
onready var properties_container = $FilterEditElement/PropertiesContainer
onready var property_elements = [
	$FilterEditElement/PropertiesLabel,
	$FilterEditElement/PropertiesContainer,
	$FilterEditElement/AddProperty,
	$FilterEditElement/Spacer
	]

func _ready():
	if main == null:
		return
	combo_box.items = main.kind_names("")
	$FilterEditElement/PropertiesContainer.parent = self
	update_properties()


func _on_DeleteButton_pressed():
	emit_signal("delete")


func _on_FilterElementWrapper_mouse_entered():
	delete_button.show()


func _on_FilterElementWrapper_mouse_exited():
	delete_button.hide()


func _on_ComboBox_option_changed(option):
	kind = option
	update_properties()
	for c in properties_container.get_children():
		c.update()


func update_properties():
	var properties = main.properties(kind, null)
	for pe in property_elements:
		pe.visible = kind != "" and properties != null and !properties.empty()

func _on_ComboBox_text_changed(text):
	kind = text
	update_properties()
	combo_box.items = main.kind_names(text)


func build_string():
	var string = "(is(" + kind + ")"
	for c in properties_container.get_children():
		string += " and " + c.build_string()
	string += ")"
	return string
