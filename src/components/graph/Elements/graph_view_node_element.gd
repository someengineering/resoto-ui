extends Node2D
class_name GraphLayoutNode

signal node_clicked

var graph_navigator:Node= null
var is_locked:bool		= false
var id:String			= ""
var parent_id:String	= ""
var children:Array		= []
var offset:Vector2		= Vector2.ZERO
var size:Vector2		= Vector2(40, 40)
var padding:Vector2		= Vector2(20, 20)
var node_repulsion		= 0.0
var min_x
var min_y
var max_x
var max_y

var metadata:Dictionary	= {}
onready var label = $Label

func _ready():
	set_title(metadata.reported.name)
	on_change_zoom(1.0)


func set_title(_title:String):
	label.text = _title
	name = "Node_" + _title
	yield(get_tree(), "idle_frame")
	label.rect_position.x = -$Label.rect_size.x/2
	label.rect_pivot_offset = $Label.rect_size/2


func on_change_zoom(new_zoom):
	label.rect_scale = Vector2.ONE / max(new_zoom, 0.8)


func _on_Button_pressed():
	emit_signal("node_clicked", id)
