extends Popup

signal range_selected(start, end, text)

onready var from := $PanelContainer/VBoxContainer/FromLineEdit
onready var to := $PanelContainer/VBoxContainer/ToLineEdit
onready var relative := $PanelContainer/VBoxContainer/ComboBox

func _ready():
	from.connect("date_changed", self, "_on_date_changed")
	to.connect("date_changed", self, "_on_date_changed")

func _on_ComboBox_option_changed(option : String):
	var text = option.to_lower()
	text = text.replace("last", "now -")
	
	var success = from.process_date(text)
	success = success and to.process_date("now")
	
	if not success:
		relative.text = ""
	else:
		yield(VisualServer, "frame_post_draw")
		relative.text = option
	
func _on_date_changed(_date):
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
