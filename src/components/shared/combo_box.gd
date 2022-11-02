tool
class_name ComboBox
extends Control

signal option_changed(option)
signal text_changed(text)

export (Array, String) var items = []
export (bool) var align_items_left:= false
export (Vector2) var button_min_size:= Vector2(1,1) setget set_button_min_size
export (bool) var clear_button_enabled:= false
export (bool) var scroll_with_keyboard:= true
export (bool) var small_results:= false

var matching_items : Array
var previous_option : String = ""

var focus := false
var showing:= false
var just_hidden:= false

export (String) var text : String setget set_text, get_text

onready var options_container := $PopupPanel/ScrollContainer/VBoxContainer
onready var options_popup := $PopupPanel
onready var line_edit := $LineEdit
onready var button := $ExpandButton


func _ready():
	$LineEdit.clear_button_enabled = clear_button_enabled


func _on_ExpandButton_pressed():
	if just_hidden:
		return
	populate_options()
	show_options()
	line_edit.grab_focus()


func _input(event:InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if options_popup.visible:
			options_popup.hide()
			get_tree().set_input_as_handled()
		elif line_edit.has_focus():
			line_edit.release_focus()
			get_tree().set_input_as_handled()


func grab_focus():
	line_edit.grab_focus()


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
			populate_options(line_edit.text)
			yield(VisualServer,"frame_post_draw")
			if options_container.get_child_count() > 0:
				options_container.get_child(0).grab_focus()
			show_options()
		if event.scancode == KEY_TAB:
			options_popup.hide()


func set_text(new_text:String) -> void:
	if $LineEdit.text != new_text:
		text = new_text
		$LineEdit.text = new_text
		emit_signal("option_changed", text)


func get_text() -> String:
	return $LineEdit.text


func populate_options(filter : String = "") -> void:
	for option in options_container.get_children():
		option.queue_free()
	
	if filter.strip_edges() == "":
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
		
		if matching_items.size() == 0:
			yield(VisualServer, "frame_post_draw")
			options_popup.hide()


func add_option(option_name : String) -> void:
	var new_button := Button.new()
	new_button.size_flags_horizontal = SIZE_EXPAND_FILL
	new_button.text = option_name
	if small_results:
		new_button.theme_type_variation = "ButtonComboList"
	new_button.align = Button.ALIGN_CENTER if not align_items_left else Button.ALIGN_LEFT
	new_button.connect("pressed", self, "_on_option_pressed", [option_name])
	options_container.add_child(new_button)


func _on_LineEdit_text_changed(new_text : String) -> void:
	emit_signal("text_changed", new_text)
	populate_options(new_text)
	show_options()
	line_edit.grab_focus()


func _on_option_pressed(option_name : String) -> void:
	line_edit.text = option_name
	options_popup.hide()
	previous_option = option_name
	emit_signal("option_changed", option_name)
	line_edit.grab_focus()
	line_edit.set_cursor_position(line_edit.text.length())


func show_options() -> void:
	if items.size() == 0:
		return
	button.flip_v = true
	options_popup.popup()
	options_popup.rect_global_position = rect_global_position + Vector2(0, rect_size.y + 2)
	options_popup.rect_size.x = rect_size.x
	options_popup.rect_size.y = min(410, items.size()*(40) + 15)


func set_items(new_items : Array) -> void:
	items.clear()
	for item in new_items:
		if item == null:
			continue
		items.append(item)


func add_item(new_item):
	items.append(new_item)


func clear() -> void:
	items.clear()


func _on_LineEdit_text_entered(new_text: String) -> void:
	emit_signal("option_changed", new_text)


func _on_LineEdit_focus_exited() -> void:
	yield(VisualServer,"frame_post_draw")
	focus = line_edit.has_focus()
	for o_button in options_container.get_children():
		if focus:
			break
		focus = focus or o_button.has_focus()
		
	if not focus:
		options_popup.hide()
		if line_edit.text != previous_option:
			emit_signal("option_changed", line_edit.text)


func _on_LineEdit_focus_entered():
	if not focus:
		previous_option = line_edit.text


func _on_PopupPanel_popup_hide():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if not options_popup.visible:
		button.flip_v = false
		just_hidden = true
		$JustHiddenTimer.start()


func _on_JustHiddenTimer_timeout():
	just_hidden = false


func set_button_min_size(_button_min_size:Vector2) -> void:
	button_min_size = _button_min_size
	if button:
		button.rect_min_size = button_min_size
