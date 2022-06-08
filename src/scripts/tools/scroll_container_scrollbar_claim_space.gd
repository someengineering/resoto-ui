extends ScrollContainer

onready var _v_scroll: ScrollBar = get_v_scrollbar()
onready var margin: MarginContainer = $Content

func _ready() -> void:
	_v_scroll.connect("visibility_changed", self, "_on_scroll_bar_visibility_changed")

func _on_scroll_bar_visibility_changed() -> void:
	if _v_scroll.visible:
		margin.set("custom_constants/margin_right", 10)
	else:
		margin.set("custom_constants/margin_right", _v_scroll.rect_size.x + 10)
