extends CanvasLayer

onready var dl := $DebugInfo/DebugLabel

func _input(event):
	if event.is_action_pressed("F1"):
		visible = !visible


func _process(_delta):
	if !visible:
		return
	dl.text = "OS.get_screen_size(): Vector2" + str(OS.get_screen_size())
	dl.text += "\nget_viewport().size: Vector2" + str(get_viewport().size)
	if OS.has_feature("HTML5"):
		var js_dpi = JavaScript.eval("getDPI()")
		dl.text += "\nJavaScript DPI: " + str(js_dpi)
		dl.text += "\nGodot DPI: " + str(OS.get_screen_dpi())
