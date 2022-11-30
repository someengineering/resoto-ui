extends ScrollContainerScrollbarClaimSpaceVertical

var scrolling_disable_time : float = 0.0
var previous_scroll : int = 0.0

func _ready():
	set_process(false)
	

func _process(delta):
	scrolling_disable_time -= delta
	scroll_vertical = previous_scroll
	if scrolling_disable_time <= 0:
		set_process(false)


func _on_Dashboard_widget_scrolling():
	scrolling_disable_time = 0.5
	previous_scroll = scroll_vertical
	set_process(true)
