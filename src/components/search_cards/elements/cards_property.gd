extends HBoxContainer

signal update_string

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
var active_edit:Node = null
var property:SearchCards.Property = null
var operator
var parent:Node = null

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
	queue_free()
	emit_signal("update_string")


func _on_PropertyOperatorButton_pressed():
	popup.property_type = property_type
	var btn = $PropertyOperatorButton
	popup.popup(Rect2(btn.rect_global_position, Vector2(20,20)))


func _on_Popup_update_operator(new_text:String, tooltip:String):
	$PropertyOperatorButton.hint_tooltip = tooltip
	$PropertyOperatorButton.text = new_text


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
	
	print(property.kind)
	property_type = property.kind if property_types.has(property_type) else "string"
	for c in $PropertyEdit.get_children():
		c.clear()
		c.hide()
	
	active_edit = property_types[property_type]
	active_edit.show()


func build_string():
	var value
	match property_type:
		"bool":
			value = active_edit.pressed
		"datetime":
			value = "%d" % [Time.get_datetime_string_from_unix_time(active_edit.unix_time, false)]
		"date":
			value = "%d" % [Time.get_datetime_string_from_unix_time(active_edit.unix_time, false).split("T")[0]]
		"string":
			value = "%d" % [active_edit.text]
	return property.name + "" + op_btn.text + "" + value

