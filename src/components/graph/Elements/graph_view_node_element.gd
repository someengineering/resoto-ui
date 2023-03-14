extends Node2D
class_name GraphLayoutNode

enum Mode {OUTBOUND, INBOUND, ROOT}

signal node_clicked

var node_display_mode:int	= Mode.OUTBOUND
var graph_navigator:Node	= null
var is_locked:bool			= false
var id:String				= ""
var node_id:String			= ""
var parent_id:String		= ""
var children:Array			= []
var offset:Vector2			= Vector2.ZERO
var size:Vector2			= Vector2(40, 40)
var padding:Vector2			= Vector2(20, 20)
var node_repulsion			= 0.0
var min_x
var min_y
var max_x
var max_y

var metadata:Dictionary	= {}
onready var label = $Label
onready var kind_label = $KindLabel

func _ready():
	set_title(metadata.reported.name)
	set_kind(metadata.reported.kind)
	set_mode(node_display_mode)
	on_change_zoom(1.0)


func set_title(_title:String):
	label.text = _title
	name = "Node_" + _title
	yield(get_tree(), "idle_frame")
	label.rect_position.x = -$Label.rect_size.x/2
	label.rect_pivot_offset = $Label.rect_size/2


func set_kind(_title:String):
	kind_label.text = _title
	yield(get_tree(), "idle_frame")
	kind_label.rect_position.x = -$KindLabel.rect_size.x/2
	kind_label.rect_pivot_offset = $KindLabel.rect_size/2


func on_change_zoom(new_zoom):
	$Label.rect_scale = Vector2.ONE / max(new_zoom, 0.8)
	$KindLabel.rect_scale = Vector2.ONE / max(new_zoom, 0.8)


func _on_Button_pressed():
	emit_signal("node_clicked", node_id)


func set_mode(_mode:int):
	node_display_mode = _mode
	if node_display_mode == Mode.ROOT:
		$Icon.color = Color("#e98df7")
		$Icon.scale = Vector2.ONE*1.5
	elif node_display_mode == Mode.INBOUND:
		$Icon.color = Color("#762dd7")
	else:
		$Icon.color = Color("#762dd7")
