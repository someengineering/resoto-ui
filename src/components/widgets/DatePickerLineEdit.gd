extends LineEdit



func _on_Button_pressed():
	$Popup.rect_size = $Popup/DatePicker.rect_size
	$Popup.popup()


func _on_DatePicker_date_picked(date):
	text = Time.get_datetime_string_from_unix_time(date, true)
