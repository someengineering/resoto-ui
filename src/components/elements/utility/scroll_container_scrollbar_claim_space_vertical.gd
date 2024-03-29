extends ScrollContainer
class_name ScrollContainerScrollbarClaimSpaceVertical

export (int) var extra_space : int = 10

onready var _v_scroll: ScrollBar = get_v_scrollbar()
onready var margin: MarginContainer = $Content


func _ready() -> void:
	_v_scroll.connect("visibility_changed", self, "_on_scroll_bar_visibility_changed")


func _on_scroll_bar_visibility_changed() -> void:
	if _v_scroll.visible:
		margin.set("custom_constants/margin_right", extra_space)
	else:
		margin.set("custom_constants/margin_right", _v_scroll.rect_size.x + extra_space)


func _on_Dashboard_need_to_resize(y):
	margin.rect_size.y = max(y, margin.rect_size.y)
	margin.rect_min_size.y = min(y, margin.rect_size.y)
