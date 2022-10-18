extends PanelContainer

func _make_custom_tooltip(for_text):
	var tooltip = preload("res://components/shared/custom_bb_hint_tooltip.tscn").instance()
	tooltip.get_node("Text").bbcode_text = for_text
	return tooltip
