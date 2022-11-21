tool
class_name TableWidget
extends BaseWidget

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

var headers_array : Array = []

onready var table = $Table
onready var header_row := $Table/ScrollContainer/TableVBox/Header
onready var rows := $Table/ScrollContainer/TableVBox/ScrollContainer/Rows
onready var scroll_rows := $Table/ScrollContainer/TableVBox/ScrollContainer
onready var scroll_container := $Table/ScrollContainer
onready var update_delay_timer := $UpdateDelayTimer
onready var pagination := $Pagination


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


func add_row(data):
	var row = HBoxContainer.new()
	row.set("custom_constants/separation", 0)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	rows.add_child(row)
	
	var n := headers_array.size()
	
	for i in n:
		var value = get_value(data, i)
		add_table_cell(row, value)
	

func add_table_cell(row, value):
	var c_id = row.get_child_count()
	var r_count = row.get_position_in_parent() % 2
	var is_header_column:bool = c_id <= header_columns_count
	var color:Color = column_header_color if is_header_column else row_color
	var table_cell = TableCell.instance()
	table_cell.data_cell = is_header_column
	table_cell.even_row = r_count == 0
	row.add_child(table_cell)
	table_cell.set_cell(str(value), color, c_id)
	

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
		table.margin_bottom = -33
		pagination.show()
		pagination.max_value = max(1, page_count)
		pagination.suffix = "of %d" % pagination.max_value
		current_page = 1
		pagination.value = 1
	else:
		table.margin_bottom = 0
		pagination.hide()


func update_table():
	if not rows or raw_data.empty() or raw_data[0] == null:
		return
		
	var n:int = max_allowed_rows if current_page < page_count - 1 else raw_data.size() % max_allowed_rows
	
	for i in n:
		var row_index = clamp(i + max_allowed_rows * current_page, 0, raw_data.size()-1)
		set_row(raw_data[row_index], i)
		
	update_delay_timer.stop()
	_on_UpdateDelayTimer_timeout()


func set_row(data, i):
	if i < rows.get_child_count():
		
		var row = rows.get_child(i)
		
		var n = headers_array.size()
		for j in n:
			row.get_child(j).cell_text = str(get_value(data, j))
	else:
		add_row(data)

func _on_Rows_resized():
	if is_instance_valid(rows):
		header_row.rect_size.x = rows.rect_size.x


func get_column_min_size(column : int) -> int:
	var size = -100000000000
	for row in rows.get_children():
		var cell = row.get_child(column)
		var cell_size = cell.get_min_size()
		if size < cell_size:
			size = cell_size
	size = max(size, header_row.get_child(column).get_min_size() + 24)
	return size


func set_column_size(column, size):
	for row in rows.get_children():
		var cell = row.get_child(column)
		cell.rect_min_size.x = size
		
	header_row.get_child(column).rect_min_size.x = size


func autoadjust_table():
	if first_update and header_row.get_child_count() > 0:
		first_update = false
		_on_UpdateDelayTimer_timeout()
		return
	modulate.a = 0.3
	update_delay_timer.start()


func _on_UpdateDelayTimer_timeout():
	modulate.a = 1.0
	var columns = headers_array.size()
	var columns_sizes : Array = []
	
	var total_column_width:= 0.0
	var scrollbar_size = 0 if !scroll_rows.get_v_scrollbar().visible else scroll_rows.get_v_scrollbar().rect_size.x
	for i in columns:
		var col_w = get_column_min_size(i) if i > 0 else get_column_min_size(i) + scrollbar_size
		columns_sizes.append(col_w)
		total_column_width += col_w
	
	var container_width : float = scroll_container.rect_size.x
	
	if total_column_width == 0.0:
		return
	
	if container_width > total_column_width:
		var ratio = (container_width-0.001 * header_row.get_child_count()) / total_column_width
		
		for i in columns:
			columns_sizes[i] *= ratio
	
	total_column_width = 0.0
	for i in columns_sizes:
		i = floor(i)
		total_column_width += i
		
	columns_sizes[0] += max(container_width - total_column_width, 0)
	
	for i in columns:
		var s = columns_sizes[i] if i > 0 else columns_sizes[i] - scrollbar_size
		set_column_size(i, s)
	
	scroll_container.scroll_horizontal = container_width < total_column_width


func _on_TableWidget_resized():
	if is_instance_valid(header_row):
		autoadjust_table()


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
	for row in rows.get_children():
		for cell in row.get_children():
			if cell.data_cell:
				cell.cell_color = column_header_color


func set_row_color(_new_color:Color):
	row_color = _new_color
	for row in rows.get_children():
		for cell in row.get_children():
			if not cell.data_cell:
				cell.cell_color = row_color


func set_header_color(_new_color:Color):
	header_color = _new_color
	for header in header_row.get_children():
		header.cell_color = header_color


func get_csv(sepparator := ",", end_of_line := "\n") -> String:
	var csv_array : PoolStringArray = []
	var header_array : PoolStringArray = []
	for i in range(1, header_row.get_child_count()):
		header_array.append('"%s"' % header_row.get_child(i).text)
	
	csv_array.append(header_array.join(sepparator))
	
	for i in range(0, raw_data.size()):
		var row = raw_data[i] as PoolStringArray
		row.remove(0)
		csv_array.append(row.join(sepparator))
		
	return csv_array.join(end_of_line)


func _on_Pagination_value_changed(value):
	current_page = value - 1
	update_table()

	
func get_data_count(data : Dictionary) -> int:
	return data["reported"].size()
	
	
func get_value(data : Dictionary, index : int):
	if data_source_type == DataSource.TYPES.AGGREGATE_SEARCH:
		var group_keys : Array = data["group"].keys()
		if index < group_keys.size():
			return data["group"][group_keys[index]]
			
		index = index - group_keys.size() + 1
		return data[data.keys()[index]]
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
