tool
extends DynamicLabel

const COPY_TEXT = "copied!"

var orig_text:String
var orig_size:Vector2
var timer := Timer.new()

func _ready():
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.connect("timeout", self, "show_original_text")
	connect("gui_input", self, "_on_gui_input")


func _on_gui_input(input:InputEvent):
	if not (input is InputEventMouseButton and input.pressed and input.button_index == BUTTON_LEFT):
		return
	
	if text != COPY_TEXT:
		timer.start()
		orig_text = text
		orig_size = rect_size
		text = COPY_TEXT
		rect_size = orig_size
		prev_size = Vector2.ONE
		_on_DynamicLabel_resized()
	OS.set_clipboard(orig_text)


func show_original_text():
	text = orig_text
	prev_size = Vector2.ONE
	_on_DynamicLabel_resized()
