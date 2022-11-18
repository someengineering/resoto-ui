extends HBoxContainer

signal value_changed(value)

export (String) var prefix := "" setget set_prefix
export (String) var suffix := "" setget set_suffix
export (int) var max_value := 1000000000 setget set_max_value
export (bool) var use_max_value := false
export (int) var min_value := 0 setget set_min_value
export (bool) var use_min_value := true
export (float) var value_to_set : float = 0.0

var value:int = 0 setget set_value
var minus:= false
var plus:= false

onready var change_timer:= $ChangeTimer
onready var int_edit:= $IntEdit


func _ready():
	set_value(int(value_to_set))
	int_edit.connect("value_change_done", self, "_on_IntEdit_value_change_done")
	int_edit.prefix = prefix
	int_edit.suffix = suffix
	int_edit.set_number(int_edit.old_text)
	int_edit.use_max_value = use_max_value
	int_edit.max_value = max_value
	int_edit.use_min_value = use_max_value
	int_edit.min_value = max_value


func set_prefix(_prefix:String):
	prefix = _prefix
	if not int_edit:
		return
	int_edit.prefix = prefix
	int_edit.on_text_changed(int_edit.old_text)


func set_suffix(_suffix:String):
	suffix = _suffix
	if not int_edit:
		return
	int_edit.suffix = suffix
	int_edit.on_text_changed(int_edit.old_text)


func set_max_value(_max_value:int):
	max_value = _max_value
	$PlusButton.disabled = use_max_value and value >= max_value
	if not int_edit:
		return
	int_edit.max_value = max_value
	int_edit.on_text_changed(int_edit.old_text)


func set_min_value(_min_value:int):
	min_value = _min_value
	$MinusButton.disabled = use_min_value and value <= min_value
	if not int_edit:
		return
	int_edit.min_value = min_value
	int_edit.on_text_changed(int_edit.old_text)


func set_value(_new:int) -> void:
	value = _new
	$MinusButton.disabled = value <= min_value
	$PlusButton.disabled = use_max_value and value >= max_value
	emit_signal("value_changed", value)
	if int_edit:
		int_edit.old_text = str(value)
		int_edit.set_number(int_edit.old_text)


func reset_timer():
	change_timer.stop()
	change_timer.wait_time = 0.3


func get_value():
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
	
	if (use_max_value and value + add_value > max_value):
		return
	if (use_min_value and value + add_value < min_value):
		return
	
	if not use_min_value and not use_max_value:
		set_value(int(value + add_value))
	else:
		if use_max_value and not use_min_value:
			set_value(int(min(value + add_value, max_value)))
		elif use_min_value and not use_max_value:
			set_value(int(max(value + add_value, min_value)))
		else:
			set_value(int(clamp(value + add_value, min_value, max_value)))
	
	if use_min_value and value <= min_value:
		$MinusButton.disabled = true
	else:
		$MinusButton.disabled = false
	if use_max_value and value >= max_value:
		$PlusButton.disabled = true
	else:
		$PlusButton.disabled = false


func _on_ChangeTimer_timeout():
	change_timer.wait_time = 0.06
	change_value(minus)


func _on_IntEdit_value_change_done(_value:int):
	get_value()


func _on_MinusButton_mouse_exited():
	_on_MinusButton_button_up()


func _on_PlusButton_mouse_exited():
	_on_PlusButton_button_up()
