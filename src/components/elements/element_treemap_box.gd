extends MarginContainer

signal pressed

var element_color := Color.white
var label := ""
var value := 0.0
var final_size := Vector2.ZERO

onready var text_label = $Center/C/Z/Label
onready var scaler = $Center/C/Z


func _ready():
	text_label.text = label + "\n(" + str(value) + ")"
	$Button.hint_tooltip = label + ": " + str(value)
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


func _on_Button_pressed():
	emit_signal("pressed")
