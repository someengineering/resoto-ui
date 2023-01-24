extends ViewportContainer

func _input( event ):
	if event is InputEventMouse:
		var mouse_event = event.duplicate()
		mouse_event.position = get_global_transform().xform_inv(event.global_position)
		$Viewport.unhandled_input(mouse_event)
	else:
		$Viewport.unhandled_input(event)
