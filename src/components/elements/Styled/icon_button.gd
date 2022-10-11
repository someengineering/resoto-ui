tool
extends Button

export (Texture) var icon_tex setget set_icon_tex
export var icon_margin:int = 4 setget set_icon_margin
export var flip_h:bool = false setget set_flip_h
export var flip_v:bool = false setget set_flip_v

onready var icon_node = $Margin/Icon


func _ready():
	icon_node.texture = icon_tex
	_t.style(icon_node, _t.col.C_LIGHT)
	connect("pressed", self, "_on_IconButton_mouse_exited")


func set_icon_tex(_icon_tex:Texture):
	icon_tex = _icon_tex
	if has_node("Margin/Icon"):
		$Margin/Icon.texture = icon_tex


func set_icon_margin(_icon_margin:int):
	icon_margin = _icon_margin
	if has_node("Margin"):
		$Margin.add_constant_override("margin_bottom", icon_margin)
		$Margin.add_constant_override("margin_top", icon_margin)
		$Margin.add_constant_override("margin_left", icon_margin)
		$Margin.add_constant_override("margin_right", icon_margin)


func set_flip_h(_flip_h:bool):
	flip_h = _flip_h
	$Margin/Icon.flip_h = flip_h


func set_flip_v(_flip_v:bool):
	flip_v = _flip_v
	$Margin/Icon.flip_v = flip_v


func _on_IconButton_mouse_entered():
	icon_node.modulate = _t.col_map[_t.col.C_LIGHTER]


func _on_IconButton_mouse_exited():
	icon_node.modulate = _t.col_map[_t.col.C_LIGHT]
