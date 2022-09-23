extends MarginContainer

signal pressed

var element_color := Color.white
var label := ""
var value := 0.0
var final_size := Vector2.ZERO

onready var text_label = $Center/C/Z/Label


func _ready():
	text_label.text = label + "\n(" + str(value) + ")"
	$Button.hint_tooltip = label + ": " + str(value)
	$Button.modulate = element_color
	yield(VisualServer, "frame_post_draw")
	update_label_pos()


func update_label_pos():
	if final_size.x < 100 or final_size.y < 80:
		text_label.hide()
	else:
		text_label.show()
		text_label.rect_size.x = final_size.x - 10
		text_label.rect_size.y = final_size.y - 10
		text_label.rect_position = -text_label.rect_size / 2


func _on_Button_mouse_entered():
	update_label_pos()


func _on_Button_pressed():
	emit_signal("pressed")
