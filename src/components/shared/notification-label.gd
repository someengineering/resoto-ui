extends Label

var notification_count : int = 0 setget set_notification_count

func _ready():
	visible = false


func set_notification_count(count : int):
	notification_count = count
	text = str(count)
	visible = count > 0
	rect_position = Vector2.ZERO
	rect_size = Vector2.ONE
