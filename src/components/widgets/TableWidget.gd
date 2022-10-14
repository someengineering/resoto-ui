tool
class_name TableWidget
extends BaseWidget

var header_color : Color
var row_color : Color
var column_header_color : Color

const HeaderCell = preload("res://components/widgets/widget_table/widget_table_header_cell.tscn")
const TableCell = preload("res://components/widgets/widget_table/widget_table_cell.tscn")

var raw_data : Array 
var sorting_column : int = 0
var sorting_type : String = ""

var header_columns_count := 0

onready var header_row := $Table/ScrollContainer/TableVBox/Header
onready var rows := $Table/ScrollContainer/TableVBox/ScrollContainer/Rows
onready var scroll_container := $Table/ScrollContainer


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
	var c_id:= 0
	for header in headers:
		var header_cell = HeaderCell.instance()
		header_row.add_child(header_cell)
		header_cell.set_cell(header, header_color, c_id)
		header_cell.connect("sort_requested", self, "sort_by_column")
		c_id += 1


func add_row(data : Array):
	var row = HBoxContainer.new()
	row.set("custom_constants/separation", 0)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var c_id:= 0
	var r_count:= rows.get_child_count()
	rows.add_child(row)
	for value in data:
		var is_header_column:bool = c_id <= header_columns_count
		var color:Color = column_header_color if is_header_column else row_color
		var table_cell = TableCell.instance()
		table_cell.data_cell = is_header_column
		table_cell.even_row = r_count % 2 == 0
		row.add_child(table_cell)
		table_cell.set_cell(str(value), color, c_id)
		c_id += 1


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
	
	if type == DataSource.TYPES.AGGREGATE_SEARCH:
		
		var headers : Array = data[0]["group"].keys()
		var vars : Array = data[0].keys()
		vars.remove(vars.find("group"))
		headers.append_array(vars)
		set_headers(headers)
		
		var i : int = 1
		for data_row in data:
			var data_array : Array = []#[" "]
			for key in data_row["group"]:
				data_array.append(data_row["group"][key])
				
			for key in data_row:
				if key == "group":
					continue
				data_array.append(data_row[key])
			
			raw_data.append(data_array)
			i += 1
	elif type == DataSource.TYPES.SEARCH:
		var rows : Array = data.split("\n",false)
		set_headers(rows[0].split(",",false))
		rows.remove(0)
		
		for row in rows:
			row = " ,"+row
			raw_data.append(row.split(",",false))
	
	update_table()


func update_table():
	for data in raw_data:
		add_row(data)
	
	autoadjust_table()


func _on_Rows_resized():
	if is_instance_valid(rows):
		header_row.rect_size.x = rows.rect_size.x


func get_column_min_size(column : int):
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
	var columns = header_row.get_child_count()
	var columns_sizes : Array = []
	
	var total_column_width:= 0.0
	for i in columns:
		var col_w = get_column_min_size(i)
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
		set_column_size(i, columns_sizes[i])
	
	yield(VisualServer,"frame_post_draw")
	scroll_container.scroll_horizontal = container_width < total_column_width


func _on_TableWidget_resized():
	if is_instance_valid(header_row):
		yield(VisualServer,"frame_post_draw")
		autoadjust_table()

func sort_by_column(column : int, ascending : bool):
	for header in header_row.get_children():
		if header.column != column:
			header.reset_sort()
	
	clear_rows()
	sorting_column = column
	
	if ascending:
		raw_data.sort_custom(self, "sort_ascending")
	else:
		raw_data.sort_custom(self, "sort_descending")
	
	update_table()


func sort_ascending(a, b):
	if a[sorting_column] < b[sorting_column]:
		return true
	return false


func sort_descending(a, b):
	if a[sorting_column] > b[sorting_column]:
		return true
	return false


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


func get_csv(sepparator := ",", end_of_line := "\n"):
	var csv_array : PoolStringArray = []
	var header_array : PoolStringArray = []
	for i in range(1, header_row.get_child_count()):
		header_array.append(header_row.get_child(i).text)
	
	csv_array.append(header_array.join(sepparator))
	
	for i in range(0, raw_data.size()):
		var row = raw_data[i] as PoolStringArray
		row.remove(0)
		csv_array.append(row.join(sepparator))
		
	return csv_array.join(end_of_line)
