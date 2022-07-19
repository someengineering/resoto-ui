extends Popup

signal range_selected(start, end, text)

onready var from := $PanelContainer/VBoxContainer/FromLineEdit
onready var to := $PanelContainer/VBoxContainer/ToLineEdit
onready var relative := $PanelContainer/VBoxContainer/ComboBox

func _ready():
	var success = from.process_date(from.text)
	success = success and to.process_date(to.text)


func _on_ComboBox_option_changed(option : String):
	var text = option.to_lower()
	text = text.replace("last", "now -")
	
	var success = from.process_date(text, false)
	success = success and to.process_date("now", false)
	
	if not success:
		relative.text = ""


func _on_CancelButton_pressed():
	hide()


func _on_AcceptButton_pressed():
	var start = from.unix_time
	var end = to.unix_time
	var text = ""
	if relative.text == "":
		text = from.text + " to " + to.text
	else:
		text = relative.text
	emit_signal("range_selected", start, end, text)
	hide()


func _on_FromLineEdit_date_changed(timestamp):
	relative.text = ""


func _on_ToLineEdit_date_changed(timestamp):
	relative.text = ""
