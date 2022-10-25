extends HBoxContainer

signal color_changed(color)

var color : Color = Style.col_map[Style.c.NORMAL] setget set_color
var color_to_set: Color
var col_regex : RegEx = RegEx.new()
var valid_text:String

onready var color_picker_button := $ColorPickerButton
onready var color_block := $ColorPickerButton/ColorPanel
onready var hex_edit := $HexEdit
onready var hex_warning := $HexEdit/Warning


func _ready():
	col_regex.compile("^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")
	set_color(color_to_set)
	hex_edit.text = color.to_html(false)


func _on_ColorPickerButton_color_changed(_color):
	set_color(_color)
	hex_edit.text = color.to_html(false)
	emit_signal("color_changed", color)


func set_color(_color:Color) -> void:
	hex_warning.hide()
	color = _color
	color_picker_button.color = _color
	color_block.modulate = _color
	hex_edit.text = _color.to_html(false)
	valid_text = hex_edit.text


func _on_HexEdit_text_changed(_new_text:String) -> void:
	validate_col_text(false)


func validate_col_text(_reset_if_invalid:bool) -> void:
	var curr_text = hex_edit.text.replace("#", "").to_lower()
	var cursor_pos = hex_edit.caret_position
	var regex_result:RegExMatch = col_regex.search(curr_text)
	hex_warning.visible = not regex_result
	if regex_result:
		curr_text = regex_result.strings[0]
		set_color(Color("#"+curr_text))
	elif _reset_if_invalid:
		hex_edit.text = valid_text
		hex_warning.hide()
	hex_edit.caret_position = cursor_pos


func check_col_text() -> void:
	validate_col_text(true)
	hex_edit.text = color.to_html(false)
	if hex_edit.has_focus():
		hex_edit.release_focus()
	emit_signal("color_changed", color)


func _on_HexEdit_text_entered(_new_text:String) -> void:
	check_col_text()
