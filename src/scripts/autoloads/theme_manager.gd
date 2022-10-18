extends Node

#------------------------------------------------------------------------------#
# Theme Manager - This handles colors of icons and changing certain elements.
#------------------------------------------------------------------------------#

const themed_group_name:= "themed"
const themed_self_group_name:= "themed_self"
const themed_col_name:= "theme_color"
enum c {C_NORMAL, C_LIGHT, C_LIGHTER, C_DARK, C_DARKER, C_BG, C_BG2, C_BG_BACK, C_CON_1, C_CON_2, C_CON_3}

var col_map:= {
	c.C_NORMAL:	Color("#0054a3"),
	c.C_LIGHT:	Color("#89d1f1"),
	c.C_LIGHTER:	Color("#ffffff"),
	c.C_DARK: 	Color("#0054a3"),
	c.C_DARKER:	Color("#0f3356"),
	c.C_BG:		Color("#0a253f"),
	c.C_BG2:		Color("#0c1822"),
	c.C_BG_BACK:	Color("#171d21"),
	# Contrast Colors
	c.C_CON_1:	Color("#e98df7"),
	c.C_CON_2:	Color("#762dd7"),
	c.C_CON_3:	Color("#3d176e")
	
}

func update_theme():
	var nodes_to_style = get_tree().get_nodes_in_group(themed_group_name)
	for i in nodes_to_style:
		var orig_alpha = i.modulate.a
		i.modulate = col_map[i.get_meta(themed_col_name)]
		i.modulate.a = orig_alpha
	
	var nodes_to_style_self = get_tree().get_nodes_in_group(themed_self_group_name)
	for i in nodes_to_style_self:
		var orig_alpha = i.self_modulate.a
		i.self_modulate = col_map[i.get_meta(themed_col_name)]
		i.self_modulate.a = orig_alpha


func style(node:Node, color_id:int):
	node.add_to_group(themed_group_name)
	node.set_meta(themed_col_name, color_id)
	var orig_alpha = node.modulate.a
	node.modulate = col_map[color_id]
	node.modulate.a = orig_alpha


func style_self(node:Node, color_id:int):
	node.add_to_group(themed_self_group_name)
	node.set_meta(themed_col_name, color_id)
	var orig_alpha = node.modulate.a
	node.self_modulate = col_map[color_id]
	node.self_modulate.a = orig_alpha
