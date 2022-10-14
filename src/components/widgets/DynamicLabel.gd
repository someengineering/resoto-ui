tool
class_name DynamicLabel
extends Label

export (bool) var can_copy_lmb := false
export (int) var min_font_size := 10
export (int) var max_font_size := 64

export (float) var base_width_ratio := 0.9

onready var font : DynamicFont = get("custom_fonts/font")

var resizeing := false
var prev_size := Vector2.ZERO

func _on_DynamicLabel_resized() -> void:
	if not resizeing and rect_size.distance_to(prev_size) > 10:
		resizeing = true
		set_process(true)
		prev_size = rect_size

func _process(_delta : float) -> void:
	if is_instance_valid(font) and resizeing:
		resizeing = false
		var size : Vector2
		var string_size := font.get_string_size(text)
		size = font.size * base_width_ratio * rect_size / string_size
		if abs(min(size.x, size.y) - font.size) > 1:
			font.size = int(clamp(min(size.x, size.y), min_font_size, max_font_size))
	set_process(false)

func get_text_size(_text := "") -> Vector2:
	if _text == "":
		_text = text
	return font.get_string_size(_text)


const COPY_TEXT = "copied!"

var orig_text:String
var orig_size:Vector2
var timer := Timer.new()

func _ready():
	if not can_copy_lmb:
		return
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.connect("timeout", self, "show_original_text")
	connect("gui_input", self, "_on_gui_input")


func _on_gui_input(input:InputEvent):
	if not can_copy_lmb:
		return
	
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
