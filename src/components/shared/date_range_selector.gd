extends Popup

signal range_selected(start, end, text)

onready var from := $PanelContainer/VBox/FromLineEdit
onready var to := $PanelContainer/VBox/ToLineEdit
onready var relative := $PanelContainer/VBox/ComboBox

onready var cancel_button:= $PanelContainer/VBox/Buttons/CancelButton
onready var accept_button:= $PanelContainer/VBox/Buttons/AcceptButton
onready var buttons := $PanelContainer/VBox/Buttons


func _ready() -> void:
	var success = from.process_date(from.text)
	success = success and to.process_date(to.text)


func _on_ComboBox_option_changed(option : String) -> void:
	var text = option.to_lower()
	text = text.replace("last", "now -")
	
	var success = from.process_date(text, false)
	success = success and to.process_date("now", false)
	
	if not success:
		relative.text = ""


func _on_CancelButton_pressed() -> void:
	hide()


func _on_AcceptButton_pressed() -> void:
	var start = from.unix_time
	var end = to.unix_time
	var text = ""
	if relative.text == "":
		text = from.text + " to " + to.text
	else:
		text = relative.text
	emit_signal("range_selected", start, end, text)
	hide()


func _on_FromLineEdit_date_changed(_timestamp : int) -> void:
	relative.text = ""


func _on_ToLineEdit_date_changed(_timestamp : int) -> void:
	relative.text = ""


func _on_DateRangeSelector_about_to_show():
	if _g.os == "MacOS":
		buttons.move_child(accept_button, 1)
	else:
		buttons.move_child(accept_button, 0)
