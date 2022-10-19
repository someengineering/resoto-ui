extends HBoxContainer

signal value_changed(value)

export (bool) var negative_allowed:= false

var value_to_set:float = 0
var value:int = 0 setget set_value
var minus:= false
var plus:= false

onready var change_timer:= $ChangeTimer
onready var int_edit:= $IntEdit

func _ready():
	set_value(int(value_to_set))
	int_edit.negative_allowed = negative_allowed
	int_edit.connect("value_change_done", self, "_on_IntEdit_value_change_done")


func set_value(_new:int) -> void:
	value = _new
	emit_signal("value_changed", value)
	if int_edit:
		int_edit.old_text = str(value)
		int_edit.set_number(int_edit.old_text)


func reset_timer():
	change_timer.stop()
	change_timer.wait_time = 0.3


func get_value():
	print("return value!", int(int_edit.old_text))
	value = int(int_edit.old_text)


func _on_MinusButton_button_down():
	minus = true
	reset_timer()
	change_value(true)
	change_timer.start()


func _on_MinusButton_button_up():
	minus = false
	change_timer.stop()


func _on_PlusButton_button_down():
	minus = false
	reset_timer()
	change_value(false)
	change_timer.start()


func _on_PlusButton_button_up():
	change_timer.stop()
	

func change_value(_minus:=true):
	var add_value:= 1
	if _minus:
		add_value = -1

	if negative_allowed:
		set_value(int(value + add_value))
	else:
		set_value(int(max(value + add_value, 0)))


func _on_ChangeTimer_timeout():
	change_timer.wait_time = 0.06
	change_value(minus)


func _on_IntEdit_value_change_done(_value:int):
	get_value()


func _on_MinusButton_mouse_exited():
	_on_MinusButton_button_up()


func _on_PlusButton_mouse_exited():
	_on_PlusButton_button_up()
