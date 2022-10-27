tool
class_name ClippedLabelCopyLMB
extends Label

export (String) var raw_text : String setget set_raw_text
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


func set_raw_text(new_raw_text : String) -> void:
	raw_text = new_raw_text
	update_text()


func update_text():
	text = ""
	var width := rect_size.x
	var font = get_font("font")
	var i : int = 0
	
	while font.get_string_size(text+"...  ").x < width:
		if i >= raw_text.length():
			break
		text += raw_text[i]
		i += 1
	if text != raw_text:
		text += "..."
		
	hint_tooltip = raw_text


func _on_ClippedLabel_resized():
	update_text()


func _on_gui_input(input:InputEvent):
	if not enabled or not(input is InputEventMouseButton and input.pressed and input.button_index == BUTTON_LEFT):
		return
	
	if text != COPY_TEXT:
		timer.start()
		orig_text = text
		orig_size = rect_size
		text = COPY_TEXT
		rect_min_size = orig_size
	OS.set_clipboard(raw_text)


func show_original_text():
	text = orig_text
