extends Node

#------------------------------------------------------------------------------#
# Theme Manager - This handles colors of icons and changing certain elements.
#------------------------------------------------------------------------------#

const icon_path := "res://assets/resource_icons/icon_%s.svg"
const icon_fallback := "res://assets/resource_icons/icon_resource.svg"

const themed_group_name:= "themed"
const themed_self_group_name:= "themed_self"
const themed_col_name:= "theme_color"

enum c {NORMAL, LIGHT, LIGHTER, DARK, DARKER, BG, BG2, BG_BACK, CON_1, CON_2, CON_3, ERR_MSG, WARN_MSG, STYLE_ERROR, CHECK_FAIL, CHECK_ON}

var col_map:= {
	c.NORMAL:		Color("#0054a3"),
	c.LIGHT:		Color("#89d1f1"),
	c.LIGHTER:		Color("#ffffff"),
	c.DARK: 		Color("#0054a3"),
	c.DARKER:		Color("#0f3356"),
	c.BG:			Color("#0a253f"),
	c.BG2:			Color("#0c1822"),
	c.BG_BACK:		Color("#171d21"),
	# Contrast Colors
	c.CON_1:		Color("#e98df7"),
	c.CON_2:		Color("#762dd7"),
	c.CON_3:		Color("#3d176e"),
	c.ERR_MSG:		Color("#c94224"),
	c.WARN_MSG:		Color("#cda11c"),
	# Style Error color - this is used when styling fails
	c.STYLE_ERROR:	Color("#ff00ff"),
	c.CHECK_FAIL:	Color("#f44444"),
	c.CHECK_ON:		Color("#44f470")
}

var default_colors:= {
	c.NORMAL:		Color("#0054a3"),
	c.LIGHT:		Color("#89d1f1"),
	c.LIGHTER:		Color("#ffffff"),
	c.DARK: 		Color("#0054a3"),
	c.DARKER:		Color("#0f3356"),
	c.BG:			Color("#0a253f"),
	c.BG2:			Color("#0c1822"),
	c.BG_BACK:		Color("#171d21"),
	# Contrast Colors
	c.CON_1:		Color("#e98df7"),
	c.CON_2:		Color("#762dd7"),
	c.CON_3:		Color("#3d176e"),
	c.ERR_MSG:		Color("#c94224"),
	c.WARN_MSG:		Color("#cda11c"),
	# Style Error color - this is used when styling fails
	c.STYLE_ERROR:	Color("#ff00ff"),
}

var group_colors := {
	"graph_root" : [Color("#e98df7"), Color("#3e245f")],
	"misc" : [Color("#0054a3"), Color("#89d1f1")],
	"control" : [Color("#0a826c"), Color("#ddfff9")],
	"networking" : [Color("#8e44ad"), Color("#bdc3c7")],
	"access_control" : [Color("#2980b9"), Color("#ecf0f1")],
	"storage" : [Color("#f1c40f"), Color("#34495e")],
	"database" : [Color("#16a085"), Color("#ecf0f1")],
	"compute" : [Color("#d35400"), Color("#ecf0f1")],
}

var icon_files := {
	
}


func update_theme():
	var nodes_to_style : Array = get_tree().get_nodes_in_group(themed_group_name)
	for i in nodes_to_style:
		var orig_alpha : float = i.modulate.a
		i.modulate = col_map[i.get_meta(themed_col_name)]
		i.modulate.a = orig_alpha
	
	var nodes_to_style_self : Array = get_tree().get_nodes_in_group(themed_self_group_name)
	for i in nodes_to_style_self:
		var orig_alpha : float = i.self_modulate.a
		i.self_modulate = col_map[i.get_meta(themed_col_name)]
		i.self_modulate.a = orig_alpha


func add(node:Node, color_id:int):
	node.add_to_group(themed_group_name)
	node.set_meta(themed_col_name, color_id)
	var orig_alpha : float = node.modulate.a
	node.modulate = col_map[color_id]
	node.modulate.a = orig_alpha


func add_self(node:Node, color_id:int):
	node.add_to_group(themed_self_group_name)
	node.set_meta(themed_col_name, color_id)
	var orig_alpha : float = node.modulate.a
	node.self_modulate = col_map[color_id]
	node.self_modulate.a = orig_alpha


func find_color(color:Color):
	# Compares the original modulated color to the color in the remap table
	color = color.to_html()
	for col in default_colors:
		if default_colors[col] == color:
			return col
	return c.STYLE_ERROR
