extends PanelContainer


func add_wrapper(_wrapper:Control, _outbound:=false):
	$Main.add_child(_wrapper)
	if _outbound:
		size_flags_horizontal = 0
		$Main.move_child(_wrapper, 0)

func get_children_container():
	return $Main/Children
