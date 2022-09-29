extends PopupPanel

signal update_duration_type

var duration_names:Dictionary = {
	"s": "Seconds",
	"m": "Minutes",
	"h": "Hours",
	"d": "Days",
	"w": "Weeks",
	"mo": "Months",
	"yr": "Years",
}

var duration_type:String = "d"

func _ready():
	selected_new_duration_type()


func selected_new_duration_type():
	emit_signal("update_duration_type", duration_names[duration_type])
	hide()


func _on_SecondsBtn_pressed():
	duration_type = "s"
	selected_new_duration_type()


func _on_MinutesBtn_pressed():
	duration_type = "m"
	selected_new_duration_type()


func _on_HoursBtn_pressed():
	duration_type = "h"
	selected_new_duration_type()


func _on_DaysBtn_pressed():
	duration_type = "d"
	selected_new_duration_type()


func _on_WeeksBtn_pressed():
	duration_type = "w"
	selected_new_duration_type()


func _on_MonthsBtn_pressed():
	duration_type = "mo"
	selected_new_duration_type()


func _on_YearsBtn_pressed():
	duration_type = "yr"
	selected_new_duration_type()
