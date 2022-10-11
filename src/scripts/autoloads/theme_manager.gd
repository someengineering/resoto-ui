extends Node

#------------------------------------------------------------------------------#
# Theme Manager - This handles colors of icons and changing certain elements.
#------------------------------------------------------------------------------#

const themed_group_name:= "themed"
const themed_col_name:= "theme_color"
enum col {C_NORMAL, C_LIGHT, C_LIGHTER, C_DARK, C_DARKER, C_BG, C_BG2, C_BG_BACK}

var color_map:= {
	col.C_NORMAL : { 	"dark" : Color("#0054a3"), "light" : Color("#0054a3") },
	col.C_LIGHT : { 	"dark" : Color("#89d1f1"), "light" : Color("#89d1f1") },
	col.C_LIGHTER : { 	"dark" : Color("#ffffff"), "light" : Color("#ffffff") },
	col.C_DARK : { 		"dark" : Color("#0054a3"), "light" : Color("#0054a3") },
	col.C_DARKER : { 	"dark" : Color("#0f3356"), "light" : Color("#0f3356") },
	col.C_BG : { 		"dark" : Color("#0a253f"), "light" : Color("#0a253f") },
	col.C_BG2 : { 		"dark" : Color("#0c1822"), "light" : Color("#0c1822") },
	col.C_BG_BACK : {	"dark" : Color("#171d21"), "light" : Color("#171d21") }
}

func update_theme():
	var nodes_to_style = get_tree().get_nodes_in_group(themed_group_name)
	for i in nodes_to_style:
		var orig_alpha = i.modulate.a
		i.modulate = color_map[i.get_meta(themed_col_name)].dark
		i.modulate.a = orig_alpha


func style(node:Node, color_id:int):
	node.add_to_group(themed_group_name)
	node.set_meta(themed_col_name, color_id)
	var orig_alpha = node.modulate.a
	node.modulate = color_map[color_id].dark
	node.modulate.a = orig_alpha
