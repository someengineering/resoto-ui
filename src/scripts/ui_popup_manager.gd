extends CanvasLayer

var current_popup: Popup = null
var popup_connect: Node = null

onready var popup_bg = $BG


func _enter_tree() -> void:
	_g.popup_manager = self


func on_popup_close() -> void:
	popup_bg.hide()
	current_popup.hide()
	current_popup = null


func popup_active() ->bool:
	return current_popup != null


func open_popup(_name:String) -> void:
	popup_bg.show()
	current_popup = (get_node(_name) as Popup)
	current_popup.connect("popup_hide", self, "on_popup_close", [], 4)
	current_popup.popup_centered_clamped(Vector2(0,0), 2.2)
