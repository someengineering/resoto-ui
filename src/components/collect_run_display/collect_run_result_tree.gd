extends Control

signal done_with_display

const RESOURCE_WARN_LIMIT := 10
const LOW_DESC_WARN = "Only %s resources were found. This could be caused by a configuration problem if it is not what you expect."
const NO_DESC_WARN = "No resources were found. This could be caused by a configuration problem if it is not what you expect."

var warning_icon : Texture = load("res://assets/icons/icon_warning_icon_special_contrast.svg")
var root : TreeItem
var tree_content := {
	"clouds" : {},
	"accounts" : {},
}

onready var tree := $Tree


func _ready():
	tree.set_column_title(0, "Name")
	tree.set_column_title(1, "Descendants")
	#tree.set_column_expand(1, false)
	#tree.set_column_min_width(1, 200)
	var query := "is(cloud) -[0:2]-> is(cloud, account, region)"
	API.graph_search(query, self, "list")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Collect Result display", Utils.err_enum_to_string(error), 1, self)
		return
	if _response.transformed.has("result"):
		var response = _response.transformed.result
		root = tree.create_item()
		root.set_text(0, "Graph Root")
		root.set_selectable(0, false)
		for r in response:
			if r.has("ancestors"):
				if r.ancestors.has("account"):
					# is region
					var ancestor_account_name : String = r.ancestors.account.reported.name
					if tree_content.accounts.has(ancestor_account_name):
						var region = tree.create_item(tree_content.accounts[ancestor_account_name])
						var region_name = r.reported.name
						var d_count = r.metadata.descendant_count
						region.collapsed = true
						region.set_text(0, region_name)
						region.set_selectable(0, false)
						region.set_text(1, Utils.comma_sep(d_count))
						region.set_selectable(1, false)
				else:
					# is account
					var ancestor_cloud_name : String = r.ancestors.cloud.reported.name
					if tree_content.clouds.has(ancestor_cloud_name):
						var account = tree.create_item(tree_content.clouds[ancestor_cloud_name])
						var account_name = r.reported.name
						var d_count = r.metadata.descendant_count
						account.collapsed = true
						account.set_text(0, account_name)
						account.set_selectable(0, false)
						account.set_text(1, Utils.comma_sep(d_count))
						account.set_selectable(1, false)
						tree_content.accounts[account_name] = account
			else:
				var cloud = tree.create_item(root)
				var cloud_name = r.reported.name
				var d_count = r.metadata.descendant_count
				cloud.collapsed = true
				cloud.set_text(0, cloud_name)
				cloud.set_selectable(0, false)
				cloud.set_text(1, Utils.comma_sep(d_count))
				cloud.set_selectable(1, false)
				if cloud_name != "example":
					check_d_count(cloud, d_count)
				tree_content.clouds[cloud_name] = cloud
		emit_signal("done_with_display")
		

func check_d_count(tree_item:TreeItem, d_count:float):
	if d_count <= RESOURCE_WARN_LIMIT:
		tree_item.set_icon_max_width(0, 20)
		tree_item.set_icon_modulate(0, Style.col_map[Style.c.WARN_MSG])
		tree_item.set_icon(0, warning_icon)
		var tooltip_text : String = LOW_DESC_WARN % d_count if d_count > 0 else NO_DESC_WARN
		tree_item.set_tooltip(0, tooltip_text)
		tree_item.set_custom_color(0, Style.col_map[Style.c.WARN_MSG])
		tree_item.set_custom_color(1, Style.col_map[Style.c.WARN_MSG])


var col_sort_name_asc := false
var col_sort_count_asc := true
func _on_Tree_column_title_pressed(column):
	# Sort by Name
	if column == 0:
		col_sort_name_asc = !col_sort_name_asc
		sort_child_tree_items_by_name(root, col_sort_name_asc)
	
	# Sort by Count
	elif column == 1:
		col_sort_count_asc = !col_sort_count_asc
		sort_child_tree_items_by_count(root, col_sort_count_asc)


func sort_child_tree_items_by_name(_parent:TreeItem, asc:bool):
	var tree_item_children : Array = get_item_children_and_text(_parent)
	if asc:
		tree_item_children.sort_custom(self, "sort_by_column_text_asc")
	else:
		tree_item_children.sort_custom(self, "sort_by_column_text_desc")
	for tree_item in tree_item_children:
		tree_item[0].move_to_bottom()
		sort_child_tree_items_by_name(tree_item[0], asc)


func sort_child_tree_items_by_count(_parent:TreeItem, asc:bool):
	var tree_item_children : Array = get_item_children_and_int(_parent)
	if asc:
		tree_item_children.sort_custom(self, "sort_by_column_text_asc")
	else:
		tree_item_children.sort_custom(self, "sort_by_column_text_desc")
	for tree_item in tree_item_children:
		tree_item[0].move_to_bottom()
		sort_child_tree_items_by_count(tree_item[0], asc)


static func sort_by_column_text_asc(a, b):
	return a[1] < b[1]

static func sort_by_column_text_desc(a, b):
	return a[1] > b[1]


func get_item_children(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children


func get_item_children_and_text(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append([item, item.get_text(0).to_lower()])
		item = item.get_next()
	return children

func get_item_children_and_int(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append([item, int(item.get_text(1).replace(",", ""))])
		item = item.get_next()
	return children
