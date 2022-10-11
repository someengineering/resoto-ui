tool
class_name RotatedLabel
extends Control

export (String) var text : String = "" setget set_text

onready var center_position : Vector2 = rect_position

func set_text(new_text : String):
	text = new_text
	$RotatedLabel.text = text

	yield(VisualServer,"frame_post_draw")
	rect_size.x = $RotatedLabel.rect_size.y
	rect_size.y = $RotatedLabel.rect_size.x
	rect_pivot_offset = rect_size / 2
	
	rect_position.y = center_position.y - rect_pivot_offset.y
	


func _on_RotatedLabel_item_rect_changed():
	center_position = rect_position + Vector2(0, rect_pivot_offset.y)
