extends Control

signal unread_logs_changed(count)

const MAX_MESSAGES:int = 30

var unread_log_count : int = 0

onready var container = $VBox/MainPanel/ScrollContainer/Content/ToastContainer


func _ready():
	_g.connect("toast_created", self, "add_toast")


func add_toast(_toast):
	if _toast.status == OK:
		return
	var new_toast = _toast.duplicate()
	new_toast.get_node("Main/CloseButton").hide()
	var title_add:= ""
	if _toast.from_node != null:
		title_add += " :: " + str(_toast.from_node.get_script().get_path().split("/")[-1])
	title_add += " @ " + Time.get_time_string_from_system()
	new_toast.get_node("Main/Content/Title").text += title_add
	container.add_child(new_toast)
	container.move_child(new_toast, 0)
	new_toast.modulate.a = 1.0
	
	var amount_of_toasts = container.get_child_count()
	var diff = amount_of_toasts - MAX_MESSAGES
	if diff >= 0:
		var children = container.get_children()
		for c in diff:
			children[amount_of_toasts-c-1].queue_free()
	
	if _toast.status in [1, 2]:
		new_toast.is_new = true
		unread_log_count += 1
		emit_signal("unread_logs_changed", unread_log_count)


func _on_MessageLog_visibility_changed():
	if not is_visible_in_tree():	
		for toast in container.get_children():
			toast.is_new = false
	else:
		unread_log_count = 0
		emit_signal("unread_logs_changed", unread_log_count)
