extends Control

signal done_with_display

const RESOURCE_WARN_LIMIT := 10
const LOW_DESC_WARN = "Only %s resources were found. This could be caused by a configuration problem if it is not what you expect."
const NO_DESC_WARN = "No resources were found. This could be caused by a configuration problem if it is not what you expect."

var cloud_warn_icon : Texture = preload("res://assets/icons/icon_128_cloud_warning.svg")
var cloud_icon : Texture = preload("res://assets/icons/icon_128_cloud.svg")
var acc_icon : Texture = preload("res://assets/icons/icon_128_account.svg")
var region_icon : Texture = preload("res://assets/icons/icon_128_region.svg")
var root : TreeItem
var total_counter := {}
var tree_dict := {}

onready var tree := $Tree


func refresh_results():
	tree_dict.clear()
	total_counter.clear()
	tree.clear()
	tree.set_column_title(0, "Cloud Provider")
	tree.set_column_title(1, "Number of Resources")
	var descendants_query := "aggregate(/ancestors.cloud.reported.id as cloud, /ancestors.account.reported.name as account, /ancestors.region.reported.name as region: sum(1) as count): not is(cloud, account, region, graph_root)"
	API.aggregate_search(descendants_query, self, "_on_get_descendants_query_done")


func build_counted_dict(response:Array):
	for r in response:
		if r.group.cloud == null:
			r.group.cloud = "No Cloud"
		if r.group.account == null:
			r.group.account = "No Account"
		if r.group.region == null:
			r.group.region = "No Region"
		if not tree_dict.has(r.group.cloud):
			tree_dict[r.group.cloud] = { "name" : r.group.cloud, "count" : 0, "accounts" : {}}
		if not tree_dict[r.group.cloud].accounts.has(r.group.account):
			tree_dict[r.group.cloud].accounts[r.group.account] = { "name" : r.group.account, "count" : 0, "regions" : {}}
		tree_dict[r.group.cloud].accounts[r.group.account].regions[r.group.region] = { "name" : r.group.region, "count" : r.count }
		tree_dict[r.group.cloud].accounts[r.group.account].count += r.count
		tree_dict[r.group.cloud].count += r.count


func _on_get_descendants_query_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in Collect Result display", "", 1, self)
		return
	if _response.transformed.has("result"):
		build_counted_dict(_response.transformed.result)
		
		root = tree.create_item()
		root.set_text(0, "Graph Root")
		root.set_selectable(0, false)
		
		for cloud in tree_dict.values():
			var new_cloud : TreeItem = tree.create_item(root)
			new_cloud.set_selectable(0, false)
			new_cloud.set_selectable(1, false)
			var cloud_tooltip_text : String = "Cloud: %s\nResources found: %s" % [cloud.name, Utils.comma_sep(cloud.count)]
			new_cloud.set_tooltip(0, cloud_tooltip_text)
			new_cloud.set_tooltip(1, cloud_tooltip_text)
			new_cloud.set_text(0, cloud.name)
			new_cloud.set_custom_bg_color(0, Style.col_map[Style.c.BG])
			new_cloud.set_custom_bg_color(1, Style.col_map[Style.c.BG])
			new_cloud.set_icon(0, cloud_icon)
			new_cloud.set_icon_max_width(0, 30)
			new_cloud.set_icon_modulate(0, Style.col_map[Style.c.LIGHT])
			new_cloud.set_text(1, Utils.comma_sep(cloud.count))
			if cloud.name != "example":
				check_d_count(new_cloud, cloud.count)
			
			for account in cloud.accounts.values():
				var new_acc : TreeItem = tree.create_item(new_cloud)
				new_acc.set_selectable(0, false)
				new_acc.set_selectable(1, false)
				var acc_tooltip_text : String = "Cloud: %s\nAccount: %s\nResources found: %s" % [cloud.name, account.name, Utils.comma_sep(account.count)]
				new_acc.set_tooltip(0, acc_tooltip_text)
				new_acc.set_tooltip(1, acc_tooltip_text)
				new_acc.set_text(0, account.name)
				new_acc.set_icon(0, acc_icon)
				new_acc.set_icon_max_width(0, 20)
				new_acc.set_icon_modulate(0, Style.col_map[Style.c.LIGHT])
				new_acc.set_text(1, Utils.comma_sep(account.count))
				new_acc.collapsed = true
				
				for region in account.regions.values():
					var new_region : TreeItem = tree.create_item(new_acc)
					new_region.set_selectable(0, false)
					new_region.set_selectable(1, false)
					var region_tooltip_text : String = "Cloud: %s\nAccount: %s\nRegion: %s\nResources found: %s" % [cloud.name, account.name, region.name, Utils.comma_sep(account.count)]
					new_region.set_tooltip(0, region_tooltip_text)
					new_region.set_tooltip(1, region_tooltip_text)
					new_region.set_text(0, region.name)
					new_region.set_icon(0, region_icon)
					new_region.set_icon_max_width(0, 20)
					new_region.set_icon_modulate(0, Style.col_map[Style.c.LIGHT].darkened(0.2))
					new_region.set_custom_color(0, Style.col_map[Style.c.LIGHT].darkened(0.2))
					new_region.set_custom_color(1, Style.col_map[Style.c.LIGHT].darkened(0.2))
					new_region.set_text(1, Utils.comma_sep(region.count))
			var _new_spacer : TreeItem = tree.create_item(root)

	emit_signal("done_with_display")


func add_to_total(r:Dictionary):
	if not total_counter.has(r.group.cloud):
		total_counter[r.group.cloud] = {}
	if not total_counter[r.group.cloud].has(r.group.account):
		total_counter[r.group.cloud][r.group.account] = int(r.count)
	else:
		total_counter[r.group.cloud][r.group.account] += int(r.count)


func check_d_count(tree_item:TreeItem, d_count:float):
	if d_count <= RESOURCE_WARN_LIMIT:
		tree_item.set_icon_max_width(0, 30)
		tree_item.set_icon_modulate(0, Style.col_map[Style.c.WARN_MSG])
		tree_item.set_icon(0, cloud_warn_icon)
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
