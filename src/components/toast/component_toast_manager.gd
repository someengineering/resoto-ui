extends Control

const Toast = preload("res://components/toast/toast_component_toast.tscn")

var toasts:Array = []
var toast_padding:int = 10

# default values for toasts
var is_closed:bool = false
var title:String = ""
var description:String = ""
var status:int = 0
var duration:float = 2.0
var is_closable:bool = true

onready var toast_anchor = $Anchor
onready var tween:Tween = $MoveToastsTween


func _ready():
	_g.connect("add_toast", self, "on_add_toast")
	_g.connect("toast_click", self, "_on_toast_clicked")


func on_add_toast(_title:String, _description:String=description, _status:int=status, _from:Node=null, _duration:float = duration, _is_closable:bool=is_closable):
	var toast = Toast.instance()
	toast.from_node = _from
	toasts.push_front(toast)
	toast_anchor.add_child(toast)
	
	toast.connect("closed", self, "on_toast_closed", [toast], 4)
	toast.open(_title, _description, _status, _duration, _is_closable)
	toast.rect_position = Vector2(-toast.rect_size.x - toast_padding, -toast.rect_size.y - toast_padding)
	
	_g.emit_signal("toast_created", toast)
	
	for i in toasts:
		move_toasts()


func get_toast_position(id:int):
	if id > toasts.size():
		return
	
	var total_height = 0
	for i in toasts.size():
		total_height -= toasts[i].rect_size.y + toast_padding
		if i == id:
			break
	return total_height


func move_toasts():
	for i in toasts.size():
		var new_y_pos = get_toast_position(i)
		tween.interpolate_property(toasts[i], "rect_position:y", toasts[i].rect_position.y, new_y_pos, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()


func on_toast_closed(toast:Control):
	toasts.erase(toast)
	toast.queue_free()
	move_toasts()


func _on_toast_clicked(_meta:String):
	match _meta:
		"reconnect":
			_g.popup_manager.open_popup("ConnectPopup")
