extends Control

const IconGraphRoot = preload("res://assets/resoto/Resoto-Logo_med.svg")

onready var icon_bg = $"%IconBG"
onready var icon_shadow = $"%IconShadow"
onready var icon_tex = $"%IconTex"


func setup(_kind:String):
	if _kind == "graph_root":
		icon_tex.texture = IconGraphRoot
		icon_shadow.texture = IconGraphRoot
		icon_bg.self_modulate = Style.group_colors[_kind][0]
		icon_tex.modulate = Color.white
		return
	
	if not _g.resoto_model.has(_kind):
		return
	
	var model_for_kind : Dictionary = _g.resoto_model[_kind]
	if model_for_kind.has("metadata") and model_for_kind.metadata.has("icon"):
		icon_tex.texture = Style.icon_files[model_for_kind.metadata.icon]
		icon_shadow.texture = Style.icon_files[model_for_kind.metadata.icon]
		icon_bg.self_modulate = Style.group_colors[model_for_kind.metadata.group][0]
		icon_tex.modulate = Style.group_colors[model_for_kind.metadata.group][1]
