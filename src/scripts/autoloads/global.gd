extends Node

signal add_toast
signal toast_created
signal ui_shrink_changed
signal connected_to_resotocore

var ui_shrink: float = 1.0 setget set_ui_shrink

var ui_version:String				= "2.0.0a24"
var resotocore_version:String		= "n/a"
const tsdb_metric_prefix:String		= "resoto_"

var is_connected_to_resotocore:bool	= false
var terminal_scrollback:Array = []
var focus_in_search:bool = false

# global references
var content_manager: Node = null
var popup_manager: CanvasLayer = null


func set_ui_shrink(new_shrink:float) -> void:
	ui_shrink = new_shrink
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920,1080), ui_shrink)
