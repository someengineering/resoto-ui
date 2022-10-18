class_name ColorControllerUi
extends MarginContainer

var color_controller : ColorController setget set_color_controller

onready var conditions_container := $VBoxContainer/ConditionsContainer
onready var condition_scene := preload("res://components/dashboard/new_widget_popup/color_condition.tscn")


func _on_Button_pressed():
	add_condition()
	

func add_condition(value : float = 0.0, color : Color = Color.black):
	var color_condition := condition_scene.instance()
	color_condition.variable_name = color_controller.control_variable
	conditions_container.add_child(color_condition)
	color_condition.color = color
	color_condition.value = value
	
	color_condition.connect("condition_changed", self, "_on_condition_changed")
	
	
func _on_condition_changed():
	color_controller.conditions.clear()
	for condition in conditions_container.get_children():
		color_controller.conditions.append(condition.condition)


func set_color_controller(controller : ColorController):
	color_controller = controller
	$VBoxContainer/HBoxContainer/PropertyLabel.text = color_controller.property
