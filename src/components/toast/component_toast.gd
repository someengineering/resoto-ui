extends PanelContainer

const SUCCESS_COLOR = "#27ae60"
const ERROR_COLOR = "#c0392b"
const WARN_COLOR = "#e67e22"
const INFO_COLOR = "#2c3e50"

enum {STATUS_SUCCESS, STATUS_ERROR, STATUS_WARN, STATUS_INFO}

signal opened
signal closed

var is_closed:bool = false
var title:String = ""
var description:String = ""
var status:int = STATUS_SUCCESS
var duration:float = 4.0
var is_closable:bool = true
var from_node:Node = null

onready var tween:Tween = $Tween


func open(_title:String, _description:String=description, _status:int=status, _duration:float = duration, _is_closable:bool=is_closable):
	$Main/Content/Title.text = _title
	
	if _description != "":
		$Main/Content/Description.show()
		$Main/Content/Description.text = _description
	
	match _status:
		STATUS_SUCCESS:
			self_modulate = SUCCESS_COLOR
		STATUS_ERROR:
			self_modulate = ERROR_COLOR
		STATUS_WARN:
			self_modulate = WARN_COLOR
		STATUS_INFO:
			self_modulate = INFO_COLOR
	
	$DisappearTimer.wait_time = _duration
	$DisappearTimer.start()
	
	if not _is_closable:
		$Main/CloseButton.hide()
	show()
	rect_pivot_offset = rect_size/2
	rect_scale = Vector2.ZERO
	
	emit_signal("opened")
	tween.interpolate_property(self, "rect_scale", Vector2.ONE*0.5, Vector2.ONE, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 0, 1, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()


func close():
	if is_closed:
		return
	is_closed = true
	tween.interpolate_property(self, "rect_scale", Vector2.ONE, Vector2.ONE*0.5, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 1, 0, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()


func _on_CloseButton_pressed():
	close()


func _on_DisappearTimer_timeout():
	close()


func _on_Tween_tween_all_completed():
	if is_closed:
		emit_signal("closed")
		hide()
