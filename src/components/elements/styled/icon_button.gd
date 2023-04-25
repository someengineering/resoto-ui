tool
extends Button

export (Texture) var icon_tex:Texture setget set_icon_tex
export (bool) var add_to_style:= true setget set_add_to_style
export var icon_margin:int = 4 setget set_icon_margin
export var flip_h:bool = false setget set_flip_h
export var flip_v:bool = false setget set_flip_v

onready var icon_node = $Margin/Icon


func _ready() -> void:
	icon_node.texture = icon_tex
	if add_to_style:
		Style.add(icon_node, Style.c.LIGHT)
	connect("pressed", self, "_on_IconButton_mouse_exited")


func set_add_to_style(_add_to_style:bool) -> void:
	add_to_style = _add_to_style
	if has_node("Margin/Icon"):
		if add_to_style:
			$Margin/Icon.modulate = Style.col_map[Style.c.LIGHT]
		else:
			$Margin/Icon.modulate = Color(1,1,1,0.9)


func set_icon_tex(_icon_tex:Texture) -> void:
	icon_tex = _icon_tex
	if has_node("Margin/Icon"):
		$Margin/Icon.texture = icon_tex


func set_icon_margin(_icon_margin:int) -> void:
	icon_margin = _icon_margin
	if has_node("Margin"):
		$Margin.add_constant_override("margin_bottom", icon_margin)
		$Margin.add_constant_override("margin_top", icon_margin)
		$Margin.add_constant_override("margin_left", icon_margin)
		$Margin.add_constant_override("margin_right", icon_margin)


func set_flip_h(_flip_h:bool) -> void:
	flip_h = _flip_h
	$Margin/Icon.flip_h = flip_h


func set_flip_v(_flip_v:bool) -> void:
	flip_v = _flip_v
	$Margin/Icon.flip_v = flip_v


func _on_IconButton_mouse_entered() -> void:
	if disabled:
		return
	if add_to_style:
		icon_node.modulate = Style.col_map[Style.c.LIGHTER]
	else:
		icon_node.modulate.a = 1.0


func _on_IconButton_mouse_exited() -> void:
	if add_to_style:
		icon_node.modulate = Style.col_map[Style.c.LIGHT]
	else:
		icon_node.modulate.a = 0.9
