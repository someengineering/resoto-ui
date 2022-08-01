tool
extends Control

signal option_changed(option)

export (Array, String) var items

var matching_items : Array
export (String) var text : String setget set_text, get_text

onready var options_container := $PopupPanel/ScrollContainer/VBoxContainer
onready var options_popup := $PopupPanel
onready var line_edit := $LineEdit


func _on_Button_pressed():
	populate_options()
	show_options()
	line_edit.grab_focus()

func set_text(new_text:String) -> void:
	if text != new_text:
		text = new_text
		$LineEdit.text = new_text
		emit_signal("option_changed", text)
	
func get_text() -> String:
	return $LineEdit.text
	

func populate_options(filter : String = "") -> void:
	for option in options_container.get_children():
		option.queue_free()
	if filter == "":
		for item in items:
			add_option(item)
	else:
		matching_items.clear()
		for item in items:
			var item_text = item.to_lower()
			var edit_text = line_edit.text.to_lower()
			if item_text.begins_with(edit_text) and not item in matching_items:
				matching_items.append(item)
				
		for item in items:
			var item_text = item.to_lower()
			var edit_text = line_edit.text.to_lower()
			if edit_text in item_text and not item in matching_items:
				matching_items.append(item)
				
		for item in matching_items:
			add_option(item)
			
func add_option(option_name : String) -> void:
	var button := Button.new()
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.text = option_name
	button.connect("pressed", self, "_on_option_pressed", [option_name])
	options_container.add_child(button)

func _on_LineEdit_text_changed(new_text : String) -> void:
	populate_options(new_text)
	show_options()
	line_edit.grab_focus()

func _on_option_pressed(option_name : String) -> void:
	line_edit.text = option_name
	options_popup.hide()
	emit_signal("option_changed", option_name)
	
func show_options() -> void:
	options_popup.popup()
	options_popup.rect_global_position = rect_global_position + Vector2(0, rect_size.y+10)
	options_popup.rect_size.x = rect_size.x
	options_popup.rect_size.y = min(400, items.size()*(29) + 5)

func set_items(new_items : Array) -> void:
	items.clear()
	for item in new_items:
		items.append(item)
		
func add_item(new_item):
	items.append(new_item)
	
func clear() -> void:
	items.clear()

func _on_LineEdit_text_entered(new_text: String) -> void:
	emit_signal("option_changed", new_text)


func _on_LineEdit_gui_input(event) -> void:
	if event is InputEventMouseButton :
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				line_edit.deselect()
			populate_options(line_edit.text)
			if line_edit.has_selection():
				var to = line_edit.get_selection_to_column()
				var from = line_edit.get_selection_from_column()
				show_options()
				line_edit.grab_focus()
				if from != -1 and to != -1:
					yield(VisualServer,"frame_post_draw")
					line_edit.select(from, to)
			
	if event is InputEventKey:
		if event.scancode == KEY_DOWN and event.is_pressed():
			yield(VisualServer,"frame_post_draw")
			if options_container.get_child_count() > 0:
				options_container.get_child(0).grab_focus()


func _on_LineEdit_focus_exited() -> void:
	yield(VisualServer,"frame_post_draw")
	var focus = line_edit.has_focus()
	for button in options_container.get_children():
		if focus:
			break
		focus = focus or button.has_focus()
		
	if not focus:
		options_popup.hide()
		emit_signal("option_changed", line_edit.text)
