extends Node2D
class_name GraphLayoutNode

const GraphRootCrosshair = preload("res://components/neighbourhood/elements/neighbourhood_node_main_crosshair.tscn")
const IconGraphRoot = preload("res://assets/resoto/Resoto-Logo_med.svg")

enum Mode {OUTBOUND, INBOUND, ROOT}

signal node_clicked
signal node_hovering(node_id, metadata)
signal node_unhovering

var node_display_mode:int	= Mode.OUTBOUND
var graph_navigator:Node	= null
var is_locked:bool			= false
var id:String				= ""
var node_id:String			= ""
var parent_id:String		= ""
var crosshair:Node2D		= null
var main_color:Color		= Color.red

var metadata:Dictionary	= {}
onready var label = $Label
onready var kind_label = $KindLabelBG


func _ready():
	set_mode(node_display_mode)
	set_title(metadata.reported.name)
	set_group_color(metadata.reported.kind)
	set_kind(metadata.reported.kind)
	on_change_zoom(1.0)


func set_title(_title:String):
	label.text = Utils.truncate_string(_title, label.get_font("font"), 250)
	name = "Node_" + _title


func set_kind(_kind:String):
	set_kind_icon(_kind)
	$KindLabelBG/KindLabelText.text = _kind


func set_kind_icon(_kind:String):
	if _kind == "graph_root":
		$IconBG/Icon.texture = IconGraphRoot
		$IconBG/IconShadow.texture = IconGraphRoot
		return
	
	if not _g.resoto_model.has(metadata.reported.kind):
		return
	
	var model_for_kind : Dictionary = _g.resoto_model[metadata.reported.kind]
	if model_for_kind.has("metadata") and model_for_kind.metadata.has("icon"):
		$IconBG/Icon.texture = Style.icon_files[model_for_kind.metadata.icon]
		$IconBG/IconShadow.texture = Style.icon_files[model_for_kind.metadata.icon]


func set_group_color(_kind:String):
	if _kind == "graph_root":
		$IconBG.self_modulate = Style.group_colors[_kind][0]
		$IconBG/Icon.modulate = Color.white
		$KindLabelBG.self_modulate = Style.group_colors[_kind][0]
		$KindLabelBG/KindLabelText.modulate = Style.group_colors[_kind][1]
		main_color = $KindLabelBG.self_modulate
		return
	
	if not _g.resoto_model.has(metadata.reported.kind):
		return
	
	var model_for_kind : Dictionary = _g.resoto_model[metadata.reported.kind]
	if model_for_kind.has("metadata") and model_for_kind.metadata.has("group"):
		$IconBG.self_modulate = Style.group_colors[model_for_kind.metadata.group][0]
		$IconBG/Icon.modulate = Style.group_colors[model_for_kind.metadata.group][1]
		$KindLabelBG.self_modulate = Style.group_colors[model_for_kind.metadata.group][0]
		$KindLabelBG/KindLabelText.modulate = Style.group_colors[model_for_kind.metadata.group][1]
		main_color = $KindLabelBG.self_modulate


onready var icon_bg = $IconBG
func on_change_zoom(new_zoom):
	var scaled_zoom : float = clamp(new_zoom+0.4, 0.1, 1.0)
	scale = Vector2.ONE / scaled_zoom / scaled_zoom
	label.visible = scale.x < 4.5
	kind_label.visible = scale.x < 4.5
		
	if crosshair:
		crosshair.scale = Vector2.ONE * clamp(scale.x, 3.0, 5.0)


func _on_Button_pressed():
	emit_signal("node_clicked", node_id)


func set_mode(_mode:int):
	node_display_mode = _mode
	if node_display_mode == Mode.ROOT:
		crosshair = GraphRootCrosshair.instance()
		add_child(crosshair)
		move_child(crosshair, 0)
		crosshair.scale = Vector2.ONE/scale
		$IconBG.self_modulate = Color("#e98df7")
		$IconBG/Icon.modulate = Color("#3e245f")


func _on_Button_mouse_entered():
	modulate = Color(1.3, 1.3, 1.3, 1.0)
	if crosshair:
		crosshair.modulate /= 1.15
	emit_signal("node_hovering", node_id, metadata)


func _on_Button_mouse_exited():
	modulate = Color.white
	if crosshair:
		crosshair.modulate = Color.white
	emit_signal("node_unhovering", node_id)


func _exit_tree():
	emit_signal("node_unhovering", node_id)
