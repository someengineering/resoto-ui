class_name ComponentContainer
extends MarginContainer

signal started

export (String) var view : String = ""
export (String) var wait_signal : String = ""

var navigation_arguments : Dictionary = {}
var enabled := true

onready var component := get_child(0)


func show():
	.show()
	if is_instance_valid(component) and component.has_method("start"):
		component.start()
		if component.has_signal(wait_signal):
			yield(component, wait_signal)
		emit_signal("started")


func apply_navigation_arguments():
	pass


func update_navigation_arguments(args : Dictionary):
	if not enabled:
		return
	navigation_arguments = args
	navigation_arguments["view"] = view
	UINavigation.set_current_navigation_state(navigation_arguments)
