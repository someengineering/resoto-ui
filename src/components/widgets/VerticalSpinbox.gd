extends VBoxContainer

signal value_changed(value)

export (int) var maximum := 23

var value setget set_value
var text setget set_text

onready var edit := $Edit

func _ready():
	edit.connect("text_entered", self, "set_text")
	edit.connect("focus_exited", self, "set_text")
	edit.connect("focus_entered", self, "_on_focus_entered")
	
func set_text(new_text := edit.text):
	self.value = int(new_text)
	
func _on_focus_entered():
	yield(VisualServer,"frame_post_draw")
	edit.select_all()


func _on_Add_pressed():
	self.value = int(edit.text) + 1


func _on_Sub_pressed():
	self.value = int(edit.text) - 1

func set_value(new_value : int):
	value = clamp(new_value, 0, maximum)
	edit.text = "%02d" % value
	emit_signal("value_changed", value)
	
