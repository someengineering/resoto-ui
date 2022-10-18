tool
extends Control

signal date_picked(date)

const days := ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
const months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "Nombember", "December"]

onready var date_label := $VBoxContainer/CurrentDateContainer/Label
onready var current_date_dict := Time.get_datetime_dict_from_system()
onready var current_date := Time.get_unix_time_from_system()
onready var grid_container := $VBoxContainer/GridContainer
onready var hour_edit := $VBoxContainer/TimePicker/Hour
onready var minute_edit := $VBoxContainer/TimePicker/Minute

func _ready() -> void:
	hour_edit.value = current_date_dict["hour"]
	hour_edit.connect("value_changed", self, "_on_Hour_value_changed")
	minute_edit.value =  current_date_dict["minute"]
	minute_edit.connect("value_changed", self, "_on_Minute_value_changed")
	refresh_calendar()
	
func refresh_calendar(date_dict : Dictionary = current_date_dict) -> void:
	
	date_label.text = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_dict(date_dict))
	
	var day = date_dict["day"]
	var month = date_dict["month"]
	var year = date_dict["year"]
	
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
	var label := Label.new()
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	for d in days:
		var l = label.duplicate()
		l.text = d
		grid_container.add_child(l)
	
	var first = Time.get_unix_time_from_datetime_string("%d-%d-01T%d:%d:00" % [year, month, current_date_dict["hour"], current_date_dict["minute"]])
	var first_dict = Time.get_date_dict_from_unix_time(first)
	
	var previous = first - 3600*24*first_dict["weekday"]
	var prev_dict = Time.get_date_dict_from_unix_time(previous)

	var group := ButtonGroup.new()
	
	for i in first_dict["weekday"]:
		var b := Button.new()
		b.text = str(prev_dict["day"])
		b.toggle_mode = true
		b.group = group
		b.self_modulate.a = 0.2
		b.connect("pressed", self, "pick_date", [previous])
		previous += 3600*24
		prev_dict = Time.get_date_dict_from_unix_time(previous)
		grid_container.add_child(b)
		
	for i in (42 - grid_container.get_child_count() + 7):
		var b := Button.new()
		b.text = str(first_dict["day"])
		b.toggle_mode = true
		b.group = group
		b.connect("pressed", self, "pick_date", [first])
		grid_container.add_child(b)

		if first_dict["day"] == day and first_dict["month"] == month:
			b.pressed = true
		if first_dict["month"] != month:
			b.self_modulate.a = 0.2
		first += 3600*24
		first_dict = Time.get_date_dict_from_unix_time(first)
		
func pick_date(date : int) -> void:
	var new_date_dict = Time.get_datetime_dict_from_unix_time(date)
	if new_date_dict["month"] != current_date_dict["month"] or new_date_dict["year"] != current_date_dict["year"]:
		refresh_calendar(new_date_dict)
	current_date = date
	current_date_dict = new_date_dict
	date_label.text = Time.get_date_string_from_unix_time(date)
	emit_signal("date_picked", date)

func _on_PrevYear_pressed() -> void:
	current_date_dict["year"] -= 1
	refresh_calendar()


func _on_PrevMonth_pressed() -> void:
	current_date_dict["month"] = wrapi(current_date_dict["month"] - 1, 1, 13)
	refresh_calendar()


func _on_NextMonth_pressed() -> void:
	current_date_dict["month"] = wrapi(current_date_dict["month"] + 1, 1, 13)
	refresh_calendar()


func _on_NextYear_pressed() -> void:
	current_date_dict["year"] += 1
	refresh_calendar()

func _on_Hour_value_changed(value : int) -> void:
	current_date_dict["hour"] = value
	current_date = Time.get_unix_time_from_datetime_dict(current_date_dict)
	emit_signal("date_picked", current_date)


func _on_Minute_value_changed(value : int) -> void:
	current_date_dict["minute"] = value
	current_date = Time.get_unix_time_from_datetime_dict(current_date_dict)
	emit_signal("date_picked", current_date)
