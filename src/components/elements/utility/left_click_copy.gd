extends Label
class_name RightClickCopyLabel

export (bool) var enabled:= true

const COPY_TEXT = "copied!"

var orig_text:String
var orig_size:Vector2
var timer := Timer.new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.connect("timeout", self, "show_original_text")
	connect("gui_input", self, "_on_gui_input")


func _on_gui_input(input:InputEvent):
	if not enabled or not(input is InputEventMouseButton and input.pressed and input.button_index == BUTTON_LEFT):
		return
	
	if text != COPY_TEXT:
		timer.start()
		orig_text = text
		orig_size = rect_size
		text = COPY_TEXT
		rect_min_size = orig_size
	OS.set_clipboard(orig_text)


func show_original_text():
	text = orig_text
