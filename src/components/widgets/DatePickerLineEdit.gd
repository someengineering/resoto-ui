extends LineEdit

signal date_changed(timestamp)

var unix_time : int setget , get_unix_time

var previous_text

func _ready():
	connect("text_entered", self, "process_date")
	connect("focus_exited", self, "process_date")
	previous_text = text

func _on_Button_pressed() -> void:
	$Popup.rect_size = $Popup/DatePicker.rect_size
	$Popup.rect_global_position = rect_global_position + rect_size
	$Popup.rect_global_position.x -= $Popup.rect_size.x
	$Popup.popup()

func _on_DatePicker_date_picked(date : int) -> void:
	unix_time = date
	text = Time.get_datetime_string_from_unix_time(date, true)

func process_date(new_text : String = text, notify := true) -> bool:
	if new_text == "":
		return false
	text = new_text
	new_text = new_text.to_lower()
	if "now" in new_text:
		new_text = replaces_tokens(new_text)
		var regex = RegEx.new()
		regex.compile("[^\\*+\\-\\d]")
		if regex.search_all(new_text) != []:
			_g.emit_signal("add_toast", "Invalid Date", "Cannot parse date.", 1)
			text = previous_text
			return false
		else:
			var expression = Expression.new()
			expression.parse(new_text)
			var result = expression.execute()
			if result == null:
				_g.emit_signal("add_toast", "Invalid Date", "Cannot parse date.", 1)
				text = previous_text
				return false
			else:
				unix_time = result
				previous_text = text
				if notify:
					emit_signal("date_changed", unix_time)
				return true
	else:
		text = new_text.replace("/", "-")
		var date_dict : Dictionary = Time.get_datetime_dict_from_datetime_string(text, false)
		var date_ts : int = Time.get_unix_time_from_datetime_dict(date_dict)
		if date_dict == {} or date_ts == 0:
			_g.emit_signal("add_toast", "Invalid Date", "Invalid ISO8601 date string.", 1)
			text = previous_text
			return false
		else:
			text = Time.get_datetime_string_from_datetime_dict(date_dict, true)
			previous_text = text
			if notify:
				emit_signal("date_changed", unix_time)
			return true


func replaces_tokens(new_text : String) -> String:
	new_text = new_text.replace(" ", "")
	
	new_text = new_text.replace("weeks", "w")
	new_text = new_text.replace("week", "w")
	new_text = new_text.replace("days", "d")
	new_text = new_text.replace("day", "d")
	new_text = new_text.replace("hours", "h")
	new_text = new_text.replace("hour", "h")
	new_text = new_text.replace("minutes", "m")
	new_text = new_text.replace("minute", "m")
	new_text = new_text.replace("seconds", "s")
	new_text = new_text.replace("second", "s")


	new_text = new_text.replace("now", str(Time.get_unix_time_from_system()))
	new_text = new_text.replace("w", "*7*24*3600")
	new_text = new_text.replace("d", "*24*3600")
	new_text = new_text.replace("h", "*3600")
	new_text = new_text.replace("m", "*60")
	new_text = new_text.replace("s", "")
	return new_text
	
	
func get_unix_time():
	process_date(text, false)
	return unix_time
