extends PanelContainer

var target:Node = null


func _ready():
	Style.add_self(self, Style.c.DARKER)


func get_drag_data(position:Vector2):
	if target:
		target.start_drag(position)
