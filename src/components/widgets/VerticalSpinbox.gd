extends VBoxContainer

signal value_changed(value)

export (int) var maximum := 23

var value setget set_value
var text setget set_text

onready var edit := $Edit

func _ready() -> void:
	edit.connect("text_entered", self, "set_text")
	edit.connect("focus_exited", self, "set_text")
	edit.connect("focus_entered", self, "_on_focus_entered")
	
func set_text(new_text : String = edit.text) -> void:
	self.value = int(new_text)
	
func _on_focus_entered() -> void:
	yield(VisualServer,"frame_post_draw")
	edit.select_all()


func _on_Add_pressed() -> void:
	self.value = int(edit.text) + 1


func _on_Sub_pressed() -> void:
	self.value = int(edit.text) - 1

func set_value(new_value : int) -> void:
	value = clamp(new_value, 0, maximum)
	edit.text = "%02d" % value
	emit_signal("value_changed", value)
	
