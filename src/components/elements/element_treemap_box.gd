extends MarginContainer

signal pressed_lmb
signal pressed_rmb

var element_color : Color	= Color.white
var element_name : String	= ""
var value : float			= 0.0
var final_size : Vector2	= Vector2.ZERO

onready var text_label := $Center/C/Z/Label
onready var scaler := $Center/C/Z


func _ready():
	var value_str : String = Utils.comma_sep(value)
	text_label.text = element_name + "\n(" + value_str + ")"
	$Button.hint_tooltip = element_name + ": " + value_str
	$Button.modulate = element_color
	var font_color: Color = Style.col_map[Style.c.BG2] if element_color.get_luminance() > 0.46 else Style.col_map[Style.c.LIGHT]
	text_label.add_color_override("font_color", font_color)
	yield(VisualServer, "frame_post_draw")
	update_label_pos()


func update_label_pos():
	text_label.show()
	if final_size.x < 30 or final_size.y < 30:
		text_label.hide()
	elif final_size.x < 60 or final_size.y < 40:
		text_label.rect_size = (final_size - Vector2(2,2)) * 2.0 # / 0.5
		text_label.rect_position = -text_label.rect_size / 2
		scaler.scale = Vector2.ONE * 0.5
	elif final_size.x < 150 or final_size.y < 120:
		text_label.rect_size = (final_size - Vector2(7,7)) / 0.7
		text_label.rect_position = -text_label.rect_size / 2
		scaler.scale = Vector2.ONE * 0.7
	else:
		text_label.rect_size = final_size - Vector2(10,10)
		text_label.rect_position = -text_label.rect_size / 2
		scaler.scale = Vector2.ONE


func _on_Button_mouse_entered():
	update_label_pos()


func _on_Button_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			emit_signal("pressed_lmb", self)
		elif event.button_index == BUTTON_RIGHT:
			emit_signal("pressed_rmb", self)
