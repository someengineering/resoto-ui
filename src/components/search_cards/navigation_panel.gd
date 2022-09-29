extends PanelContainer

const TRAVERSAL_STRING_MID = "-[{in}:{out}]-"

signal delete
signal update_string

var main:Node = null
var inbound:bool = false
var outbound:bool = true
var include_result:bool = false
var query_string:String = "-->"
var manual_mode:bool = false setget set_manual_mode

onready var icons = $VBoxContainer/Icons
onready var line_edit = $VBoxContainer/ManualEdit

onready var icon_inbound =	$VBoxContainer/Icons/Inbound
onready var icon_a_in = 	$VBoxContainer/Icons/ArrowLeft
onready var icon_outbound =	$VBoxContainer/Icons/Outbound
onready var icon_a_out = 	$VBoxContainer/Icons/ArrowRight
onready var icon_center = 	$VBoxContainer/Icons/Result


func _ready():
	update_graphics()
#	build_string()


func build_string():
	var t_string:= TRAVERSAL_STRING_MID
	
	if inbound:
		t_string = t_string.insert(0, "<")
	
	if outbound:
		t_string = t_string.insert(t_string.length(), ">")
	
	var depth = "0" if include_result else "1"
	t_string = t_string.format({"in":depth, "out":"1"})
	query_string = t_string
	update_graphics()
	return query_string


func update_graphics():
	var hl_col = ResotoTheme.ui_col_highlight
	var da_col = ResotoTheme.ui_col_mid
	icon_inbound.self_modulate = hl_col if inbound else da_col
	icon_a_in.self_modulate = hl_col if inbound else da_col
	icon_outbound.self_modulate = hl_col if outbound else da_col
	icon_a_out.self_modulate = hl_col if outbound else da_col
	icon_center.self_modulate = hl_col if include_result else da_col
	

func _on_DeleteButton_pressed():
	emit_signal("delete")


func _on_Inbound_pressed():
	if inbound and !outbound:
		inbound = false
		outbound = true
		build_string()
		return
	inbound = !inbound
	update_graphics()
	emit_signal("update_string")


func _on_Result_pressed():
	include_result = !include_result
	update_graphics()
	emit_signal("update_string")


func _on_Outbound_pressed():
	if !inbound and outbound:
		outbound = false
		inbound = true
		build_string()
		return
	outbound = !outbound
	update_graphics()
	emit_signal("update_string")


func set_manual_mode(value:bool):
	manual_mode = value
	
	if manual_mode:
		line_edit.text = query_string
		line_edit.show()
		icons.hide()
	else:
		line_edit.hide()
		icons.show()
	emit_signal("update_string")


func _on_ModeButton_pressed():
	set_manual_mode(!manual_mode)
