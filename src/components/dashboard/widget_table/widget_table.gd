class_name TableWidget
extends BaseWidget

signal scrolling

var header_color: Color
var row_color: Color
var column_header_color: Color

const HeaderCell = preload("res://components/dashboard/widget_table/widget_table_header_cell.tscn")
const TableCell = preload("res://components/dashboard/widget_table/widget_table_cell.tscn")
const DefaultSearchAttributes : Dictionary = {
	"kind" : ["reported", "kind"],
	"id" : ["reported", "id"],
	"name" : ["reported", "name"],
	"age" : ["reported", "age"],
	"last_update" : ["reported", "last_update"],
	"cloud" : ["ancestors", "cloud", "reported", "name"],
	"account" : ["ancestors", "account", "reported", "name"],
	"region" : ["ancestors", "region", "reported", "name"],
	"zone" : ["ancestors", "zone", "reported", "name"],
}

var raw_data : Array 
var sorting_column : int = -1
var sorting_type : String = ""
var first_update:= true

var header_columns_count := 0

var max_allowed_rows:int = 30
var page_count:int = 0
var current_page:int = 0

var data_source_type : int

var headers_array : PoolStringArray = []

onready var table = $Content
onready var header_row := $Content/Control/Headers
onready var rows := $Content/Table/Rows
onready var pagination := $Content/Pagination
onready var pagination_spacer := $Content/PaginationSpacer
onready var table_scroll := $Content/Table


func _ready():
	table_scroll.get_v_scrollbar().connect("value_changed", self, "_on_table_scrolling")
	table_scroll.get_h_scrollbar().connect("value_changed", self, "_on_table_scrolling")


func _on_table_scrolling(_value):
	emit_signal("scrolling")


func clear_all():
	for child in header_row.get_children():
		header_row.remove_child(child)
		child.queue_free()
	clear_rows()


func clear_rows():
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()


func set_headers(headers : Array):
	headers_array = headers
	var c_id:= 0
	for header in headers:
		var header_cell = HeaderCell.instance()
		header_row.add_child(header_cell)
		header_cell.set_cell(header, header_color, c_id)
		header_cell.connect("sort_requested", self, "sort_by_column")
		if sorting_column == c_id:
			header_cell.sorting = header_cell.Sorting.ASC if sorting_type == "asc" else header_cell.Sorting.DESC
			header_cell.update_sort_icon()
		c_id += 1
	rows.columns = headers.size()
#	header_row.columns = headers.size()



var row_data := {}
func add_row(data, row_idx):
	row_data[row_idx] = data
	# this could be moved out of the loop
	var n := headers_array.size()
	
	for cell_idx in n:
		var value = get_value(data, cell_idx)
		add_cell(row_idx, cell_idx, value)
	

func add_cell(row, cell_idx, value):
	var table_cell = TableCell.instance()
	var is_header_column:bool = cell_idx <= header_columns_count
	table_cell.data_cell = is_header_column
	table_cell.even_row = row % 2 == 0
	#table_cell.size_flags_horizontal = SIZE_EXPAND_FILL if is_header_column else SIZE_FILL
	rows.add_child(table_cell)
	var color:Color = column_header_color if is_header_column else row_color
#	prints("v:", value)
	table_cell.set_cell(str(value), color, row)


func _get_property_list() -> Array:
	var properties = []
	
	properties.append({
		name = "Widget Settings",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	properties.append({
		"name" : "header_color",
		"type" : TYPE_COLOR
	})
	
	properties.append({
		"name" : "row_color",
		"type" : TYPE_COLOR
	})
	
	properties.append({
		"name" : "column_header_color",
		"type" : TYPE_COLOR
	})
	
	return properties


func set_data(data, type):
	if raw_data.size() > 0:
		raw_data.clear()
	clear_all()
	
	data_source_type = type
	
	raw_data = data
	
	if data_source_type == DataSource.TYPES.AGGREGATE_SEARCH:
		var headers = raw_data[0]["group"].keys()
		headers.append_array(raw_data[0].keys())
		headers.erase("group")
		set_headers(headers)
	elif data_source_type == DataSource.TYPES.SEARCH:
		set_headers(DefaultSearchAttributes.keys())
		
	update_page_count(raw_data.size())
	yield(VisualServer, "frame_post_draw")
	sort_by_column(sorting_column, sorting_type == "asc")


func update_page_count(row_count : int):
	page_count = int(ceil(float(row_count) / max_allowed_rows))
	if page_count > 1:
		pagination.show()
		pagination_spacer.show()
		pagination.max_value = max(1, page_count)
		pagination.suffix = "of %d" % pagination.max_value
		current_page = 1
		pagination.value = 1
	else:
		pagination.hide()
		pagination_spacer.hide()


func update_table():
	if not rows or raw_data.empty() or raw_data[0] == null:
		return
	for c in rows.get_children():
		c.queue_free()
	yield(get_tree(), "idle_frame")
	var n:int = max_allowed_rows if current_page < page_count - 1 else raw_data.size() % max_allowed_rows
	for i in n:
		var row_index = clamp(i + max_allowed_rows * current_page, 0, raw_data.size()-1)
		set_row(raw_data[row_index], i)
	yield(VisualServer, "frame_post_draw")
	is_dirty = true
	autoadjust_table()


func set_row(data, i):
	add_row(data, i)


func _on_Rows_resized():
	if is_instance_valid(rows):
		header_row.rect_size.x = rows.rect_size.x

#
#func get_column_min_size(column : int) -> int:
#	var size = -100000000000
#	for row in rows.get_children():
#		var cell = row.get_child(column)
#		var cell_size = cell.get_min_size()
#		if size < cell_size:
#			size = cell_size
#	size = max(size, header_row.get_child(column).get_min_size() + 24)
#	return size
#
#
#func set_column_size(column, size):
#	for row in rows.get_children():
#		var cell = row.get_child(column)
#		cell.rect_min_size.x = size
#	header_row.get_child(column).rect_min_size.x = size


func autoadjust_table():
	if rows.get_child_count()==0 or raw_data.empty() or raw_data[0] == null:
		return
	header_row.rect_position.x = -table_scroll.scroll_horizontal
	if not is_dirty:
		return
	var last_width := 0.0
	
	for h in header_row.get_child_count():
		var header_cell = header_row.get_child(h)
		var body_cell = rows.get_child(h)
		
		body_cell.rect_min_size.x = max(body_cell.min_size, header_cell.min_size)
		header_cell.rect_min_size.x = max(body_cell.rect_size.x, header_cell.min_size)
	is_dirty = false


func _process(delta):
	autoadjust_table()


var is_dirty := false
func _on_TableWidget_resized():
	if is_instance_valid(header_row):
		is_dirty = true


func sort_by_column(column : int, ascending : bool):
	
	if column >= 0:
		sorting_type = "asc" if ascending else "desc"
		for header in header_row.get_children():
			if header.column != column:
				header.reset_sort()
		
		sorting_column = int(min(column, header_row.get_child_count()-1))
	
		if ascending:
			raw_data.sort_custom(self, "sort_ascending")
		else:
			raw_data.sort_custom(self, "sort_descending")
	update_table()


func sort_ascending(a, b) -> bool:
	var va = get_value(a, sorting_column)
	var vb = get_value(b, sorting_column)
	return va < vb


func sort_descending(a, b) -> bool:
	var va = get_value(a, sorting_column)
	var vb = get_value(b, sorting_column)
	return va > vb


func set_column_header_color(_new_color:Color):
	column_header_color = _new_color
	for cell in rows.get_children():
		if cell.data_cell:
			cell.cell_color = column_header_color


func set_row_color(_new_color:Color):
	row_color = _new_color
	for cell in rows.get_children():
		if not cell.data_cell:
			cell.cell_color = row_color


func set_header_color(_new_color:Color):
	header_color = _new_color
	for header in header_row.get_children():
		header.cell_color = header_color


func get_csv(sepparator := ",", end_of_line := "\n") -> String:
	var csv_array : PoolStringArray = []

	csv_array.append(headers_array.join(sepparator))
	
	for data in raw_data:
		var row : PoolStringArray = []
		for i in headers_array.size():
			row.append('"%s"' % str(get_value(data, i)))
		csv_array.append(row.join(sepparator))
		
	return csv_array.join(end_of_line)


func _on_Pagination_value_changed(value):
	current_page = value - 1
	update_table()

	
func get_data_count(data : Dictionary) -> int:
	return data["reported"].size()
	
	
func get_value(data : Dictionary, index : int):
	if data_source_type == DataSource.TYPES.AGGREGATE_SEARCH:
		var keys : Array = data["group"].keys()
		var group_keys : Array = keys.duplicate()
		var all_keys : Array = data.keys()
		all_keys.erase("group")
		keys.append_array(all_keys)
		if index < group_keys.size():
			return data["group"][group_keys[index]]
		return data[keys[index]]
	elif data_source_type == DataSource.TYPES.SEARCH:
		var key : String = DefaultSearchAttributes.keys()[index]
		var path : Array = DefaultSearchAttributes[key]
		var result = data
		for part in path:
			if part in result:
				result = result[part]
			else:
				result = ""
				break
		return result

