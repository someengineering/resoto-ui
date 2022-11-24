class_name ColorControllerUi
extends MarginContainer

signal reset_color

var random_colors : PoolStringArray = ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"]
var color_controller : ColorController = null setget set_color_controller

onready var conditions_container := $VBoxContainer/ConditionsContainer
onready var condition_scene := preload("res://components/dashboard/new_widget_popup/color_condition.tscn")


func add_condition(value : float = 0.0, color : Color = Color(0,0,0,0)):
	if color == Color(0,0,0,0):
		color = random_colors[randi()%random_colors.size()]
	var color_condition := condition_scene.instance()
	color_condition.variable_name = color_controller.control_variable
	conditions_container.add_child(color_condition)
	color_condition.color = color
	color_condition.value = value
	color_condition.connect("tree_exited", self, "_on_condition_changed")
	color_condition.connect("condition_changed", self, "_on_condition_changed")
	_on_condition_changed()
	
	
func _on_condition_changed():
	if not is_instance_valid(color_controller):
		return
	color_controller.conditions.clear()
	for condition in conditions_container.get_children():
		color_controller.conditions.append(condition.condition)
	if color_controller.conditions.empty():
		emit_signal("reset_color")


func set_color_controller(controller : ColorController):
	color_controller = controller
	$VBoxContainer/HBoxContainer/PropertyLabel.text = color_controller.property.capitalize()


func _on_AddButton_pressed():
	add_condition()
