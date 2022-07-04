extends Control

signal option_changed(option)

export (Array, String) var items

var matching_items : Array
var text : String setget set_text, get_text

onready var options_container := $PopupPanel/ScrollContainer/VBoxContainer
onready var options_popup := $PopupPanel
onready var line_edit := $LineEdit


func _on_Button_pressed():
	populate_options()
	show_options()

func set_text(new_text:String):
	text = new_text
	line_edit.text = new_text
	
func get_text() -> String:
	return $LineEdit.text
	

func populate_options(filter : String = ""):
	for option in options_container.get_children():
		option.queue_free()
	if filter == "":
		for item in items:
			add_option(item)
	else:
		matching_items.clear()
		for item in items:
			if item.begins_with(line_edit.text) and not item in matching_items:
				matching_items.append(item)
		for item in items:
			if line_edit.text in item and not item in matching_items:
				matching_items.append(item)
		for item in matching_items:
			add_option(item)
			
func add_option(option_name : String):
	var button := Button.new()
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.text = option_name
	button.connect("pressed", self, "_on_option_pressed", [option_name])
	options_container.add_child(button)

func _on_LineEdit_text_changed(new_text):
	populate_options(new_text)
	show_options()
	line_edit.grab_focus()

func _on_option_pressed(option_name : String):
	line_edit.text = option_name
	options_popup.hide()
	emit_signal("option_changed", option_name)
	
func show_options():
	options_popup.popup()
	options_popup.rect_global_position = rect_global_position + Vector2(0, rect_size.y+10)
	options_popup.rect_size.x = rect_size.x
	yield(VisualServer,"frame_post_draw")
	options_popup.rect_size.y = min(400, options_container.rect_size.y + 10)

func set_items(new_items : Array):
	items.clear()
	for item in new_items:
		items.append(item)


func _on_LineEdit_text_entered(new_text):
	emit_signal("option_changed", new_text)
