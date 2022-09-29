extends HBoxContainer

onready var property_types:Dictionary = {
	"bool": $PropertyEdit/BoolEdit,
	"date": $PropertyEdit/DatePickerLineEdit,
	"datetime":$PropertyEdit/DatePickerTimeLineEdit,
	"duration":$PropertyEdit/DurationLineEdit,
	"string":$PropertyEdit/StringEdit,
	"int32":$PropertyEdit/IntEdit,
	"int64":$PropertyEdit/IntEdit,
	"float":$PropertyEdit/FloatEdit,
	"double":$PropertyEdit/FloatEdit }

var property_name:String = ""
var property_type:String = ""
var property:SearchCards.Property = null
var operator
var parent:Node = null

onready var active_edit:Node = $PropertyEdit/StringEdit
onready var combo = $PropertyComboBox
onready var popup = $PropertyOperatorButton/Popup
onready var op_btn = $PropertyOperatorButton


func _ready():
	if parent == null:
		return
	combo.items = parent.main.properties(parent.kind, null)
	valid_property_selected()


func update():
	combo.items = parent.main.properties(parent.kind, null)
	
	
func _on_PropertyDeleteButton_pressed():
	update_string()
	queue_free()


func _on_PropertyOperatorButton_pressed():
	popup.property_type = property_type
	var btn = $PropertyOperatorButton
	popup.popup(Rect2(btn.rect_global_position, Vector2(20,20)))


func _on_Popup_update_operator(new_text:String, tooltip:String):
	$PropertyOperatorButton.hint_tooltip = tooltip
	$PropertyOperatorButton.text = new_text
	update_string()


func _on_PropertyComboBox_text_changed(new_text):
	combo.items = parent.main.properties(parent.kind, new_text)
	property_name = new_text
	set_property()


func _on_PropertyComboBox_option_changed(option):
	property_name = option
	set_property()


func valid_property_selected():
	var valid = property != null
	$PropertyOperatorButton.visible = valid
	$PropertyDeleteButton.visible = valid
	$PropertyEdit.visible = valid


func set_property():
	property = parent.main.property(parent.kind, property_name)
	valid_property_selected()
	if property == null:
		return
	
	property_type = property.kind if property_types.has(property.kind) else "string"
	for c in $PropertyEdit.get_children():
		c.hide()
	
	active_edit = property_types[property_type]
	active_edit.show()
	active_edit.clear()
	update_string()


func update_string():
	parent.emit_signal("update_string")


func build_string():
	if property == null:
		return ""
	var value
	match property_type:
		"bool":
			value = active_edit.pressed
		"datetime":
			value = "\"%s\"" % [Time.get_datetime_string_from_unix_time(active_edit.unix_time, false)]
		"date":
			value = "\"%s\"" % [Time.get_datetime_string_from_unix_time(active_edit.unix_time, false).split("T")[0]]
		"string":
			var str_val = active_edit.text
			value = "\"%s\"" % [str_val]
			if str_val.begins_with("[") or str_val.begins_with("{"):
				value = value.trim_prefix("\"")
			if str_val.ends_with("]") or str_val.begins_with("}"):
				value = value.trim_suffix("\"")
		"duration":
			value = active_edit.get_value()
		_:
			value = active_edit.text
	return property.name + op_btn.text + str(value)


func _on_value_changed(new_text):
	update_string()
