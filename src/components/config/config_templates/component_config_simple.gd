extends Control
class_name ConfigComponentSimple

signal value_field_selected
signal value_changed

var value_field = null
var kind:String = "" setget set_kind
var value setget set_value, get_value
var description:String = "" setget set_description
var key:String = "" setget set_key
var required:bool = false setget set_required
var descriptions_as_hints:bool = true
var overridden := false setget set_overridden
var text_rows := 0
var font_height := 1.0

onready var null_value = $VarContent/VarValueIsNull

func _draw():
	if value == null and required:
		var rect = get_rect()
		rect.position = -2*Vector2.ONE
		rect = rect.grow(5)
		$"%MissingRequiredLabel".show()
		draw_rect(rect, Color("#f44444"), false, 1.0)
	else:
		$"%MissingRequiredLabel".hide()

func show_description(_show:bool) -> void:
	$"%DescriptionContainer".visible = _show if description != "" else false


func set_description(_value:String) -> void:
	description = _value
	$"%DescriptionContainer".visible = description != ""
	$"%Description".text = description


func set_key(_value:String) -> void:
	key = _value
	if _value == "":
		$VarContent/VarName.hide()
	$VarContent/VarName.text = key.capitalize()


func set_overridden(o: bool):
	overridden = o
	$VarContent/OverriddenLabel.visible = o
	if overridden:
		$"%VarName".add_color_override("font_color", Style.col_map[Style.c.WARN_MSG])


func set_default(_value:bool) -> void:
	if not _value:
		return
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			set_value("")
		"int64", "int32":
			set_value(0)
		"float", "double":
			set_value(0.0)
		"boolean":
			set_value(false)


func set_required(_value:bool) -> void:
	required = _value
	if required:
		$VarContent/ButtonSetToNull.hide()
		return
	
	set_to_null(value==null)


func set_kind(_kind:String) -> void:
	kind = _kind
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			value_field = $"%VarValueTextbox"
			font_height = value_field.get_font("font").get_height()
		"int64", "int32":
			value_field = $"%VarValueInt"
		"float", "double":
			value_field = $"%VarValueFloat"
		"boolean":
			$"%BoolGroup".show()
			value_field = $"%VarValueBool"
	value_field.show()
	emit_signal("value_field_selected")


func set_value(_value) -> void:
	value = _value
	if not self.is_inside_tree():
		yield(self, "ready")
	
	if value == null:
		set_to_null(true)
		return
	
	match kind:
		"null":
			return
		"string", "date", "datetime", "duration", "trafo.duration_to_datetime":
			value_field.text = str(value)
		"int64", "int32", "float", "double":
			var new_value = str(value)
			value_field.set_number(new_value)
		"boolean":
			value_field.pressed = bool(value)
			$"%VarValueBoolLabel".text = "True" if bool(value) else "False"
		"any":
			value_field.text = JSON.print(value)


func get_value():
	if value == null:
		return null
	match kind:
		"string", "date", "datetime", "duration", "trafo.duration_to_datetime":
			return value_field.text
		"int64", "int32":
			return int(value_field.text)
		"float", "double":
			return float(value_field.text)
		"boolean":
			return bool(value_field.pressed)
		"any":
			var json_parse_result:JSONParseResult = JSON.parse(value_field.text)
			if json_parse_result.error == OK:
				return json_parse_result.result
			else:
				return str(value_field.text)


func _on_ButtonSetToNull_pressed() -> void:
	set_to_null(true)


func set_to_null(to_null:bool) -> void:
	if to_null:
		value = null
	
	if not value_field:
		yield(self, "value_field_selected")
	if not self.is_inside_tree():
		yield(self, "ready")
	
	value_field.visible = !to_null
	# Testing not showing Null at all
	null_value.hide()
#	null_value.visible = to_null
	
	$VarContent/ButtonAddValue.visible = to_null
	if not required:
		$VarContent/ButtonSetToNull.visible = !to_null


func _on_key_update(_new_key:String) -> void:
	set_key(_new_key)


func _on_ButtonAddValue_pressed() -> void:
	var new_value = null
	set_to_null(false)
	
	match kind:
		"string", "any", "date", "datetime", "duration", "trafo.duration_to_datetime":
			new_value = ""
		"int64", "int32":
			new_value = 0.0
		"float", "double":
			new_value = 0
		"boolean":
			new_value = false
	set_value(new_value)


func _on_TemplateSimple_item_rect_changed():
	if value_field == $"%VarValueTextbox" and not VisualServer.is_connected("frame_post_draw", self, "update_text_box_height"):
		VisualServer.connect("frame_post_draw", self, "update_text_box_height", [], CONNECT_ONESHOT)


func update_text_box_height():
	if text_rows != value_field.get_total_visible_rows():
		text_rows = value_field.get_total_visible_rows()
		if text_rows == 1:
			value_field.show_line_numbers = false
			value_field.rect_min_size.y = 36
		else:
			value_field.show_line_numbers = true
			value_field.rect_min_size.y = max((text_rows+1) * (font_height), 36)


func _on_VarValueTextbox_text_changed():
	update_text_box_height()
	emit_signal("value_changed", $"%VarValueTextbox".text)


func _on_VarValueBool_pressed():
	$"%VarValueBoolLabel".text = "True" if value_field.pressed else "False"
