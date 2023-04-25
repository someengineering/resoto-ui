tool
class_name LabelLeftClickCopy
extends Node

onready var parent := get_parent()

var incorrect_parent_message := "The parent of this node must have a text property to copy"

func _get_configuration_warning():
	if not is_parent_correct():
		return incorrect_parent_message
	return ''


func is_parent_correct():
	return parent != null and parent is Control and ("text" in parent or "raw_text" in parent)


func _ready():
	if not Engine.editor_hint:
		var ok = is_parent_correct()
		# For stopping execution in debugging
		assert(ok, incorrect_parent_message)
		# On release, just push a warning and free this node
		if not ok:
			push_warning(incorrect_parent_message)
			queue_free()
		else:
			parent = parent as Control
			parent.mouse_filter = Control.MOUSE_FILTER_STOP
			parent.connect("gui_input", self, "_on_parent_gui_input")


func _on_parent_gui_input(input : InputEvent):
	if not(input is InputEventMouseButton and input.pressed and input.button_index == BUTTON_LEFT):
		return
		
	var text = parent.text if not "raw_text" in parent else parent.raw_text
	_g.emit_signal("text_to_clipboard", text)

