extends Button

export (Texture) var icon_tex setget set_icon_tex

var flip_h:bool = false setget set_flip_h
var flip_v:bool = false setget set_flip_v

onready var icon_node = $Icon


func _ready():
	icon_node.texture = icon_tex
	_t.style(icon_node, _t.col.C_LIGHT)


func set_icon_tex(_icon_tex:Texture):
	icon_tex = _icon_tex
	if icon_node:
		icon_node.texture = icon_tex


func set_flip_h(_flip_h:bool):
	icon_node.flip_h = _flip_h


func set_flip_v(_flip_v:bool):
	icon_node.flip_v = _flip_v


func _on_IconButton_mouse_entered():
	icon_node.modulate = _t.col_map[_t.col.C_LIGHTER]


func _on_IconButton_mouse_exited():
	icon_node.modulate = _t.col_map[_t.col.C_LIGHT]
