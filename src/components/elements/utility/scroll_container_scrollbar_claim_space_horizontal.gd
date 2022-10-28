extends ScrollContainer

onready var _h_scroll: ScrollBar = get_h_scrollbar()
onready var margin: MarginContainer = $Content

func _ready() -> void:
	_h_scroll.connect("visibility_changed", self, "_on_scroll_bar_visibility_changed")

func _on_scroll_bar_visibility_changed() -> void:
	if _h_scroll.visible:
		margin.set("custom_constants/margin_right", 10)
	else:
		margin.set("custom_constants/margin_right", _h_scroll.rect_size.x + 10)
