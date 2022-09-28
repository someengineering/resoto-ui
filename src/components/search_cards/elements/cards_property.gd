extends HBoxContainer

signal update_string

var property_name:String = ""
var property_type:String = ""
var property:SearchCards.Property = null
var operator
var parent:Node = null

onready var combo = $PropertyComboBox
onready var popup = $PropertyOperatorButton/Popup


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


func _on_Popup_update_operator(new_text:String):
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
	property_type = property.kind
