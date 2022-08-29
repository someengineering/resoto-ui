tool
class_name TableWidget
extends BaseWidget

var header_color : Color
var row_color : Color
var column_header_color : Color

var raw_data : Array 
var sorting_column : int = 0
var sorting_type : String = ""

var header_columns_count := 0

onready var header_row := $Table/ScrollContainer/VBoxContainer/Header
onready var rows := $Table/ScrollContainer/VBoxContainer/ScrollContainer/Rows
onready var scroll_container := $Table/ScrollContainer

class RowElement extends Label:
	
	signal sort_requested(column, ascending)
	
	var color : Color setget set_color
	var rect := ColorRect.new()
	var column_id : int
	var sort_button := SortButton.new()
	
	func _init(t, c, sort_enabled := false):
		text = t
		self.color = c
		
		size_flags_horizontal = SIZE_FILL
		size_flags_vertical = SIZE_FILL
		valign = Label.VALIGN_CENTER
		align = Label.ALIGN_CENTER
#		autowrap = true
#		clip_text = true
		
		rect_min_size.y = 24
		
		if sort_enabled:
			sort_button.connect("sort_requested", self, "request_sort")
			add_child(sort_button)
			
		mouse_filter = MOUSE_FILTER_STOP
		
	func _ready():
		call_deferred("add_child", rect)
		rect.color = color
		rect.anchor_right = 1
		rect.anchor_bottom = 1
		rect.show_behind_parent = true
		rect.mouse_filter = MOUSE_FILTER_IGNORE
		column_id = get_parent().get_children().find(self)
		connect("mouse_entered", self, "on_mouse_entered")
		connect("mouse_exited", self, "on_mouse_exited")
		
	func set_color(new_color : Color):
		color = new_color
		rect.color = color
	
	func get_min_size():
		var font = get_font("font")
		return font.get_string_size(text)
		
	func request_sort():
		emit_signal("sort_requested", column_id, sort_button.ascending)
		
	func on_mouse_entered():
		rect.color = color.lightened(0.1)
		
	func on_mouse_exited():
		rect.color = color
		
class SortButton extends Button:
	signal sort_requested
	var ascending := false
	func _ready():
		anchor_right = 1
		anchor_left = 1
		margin_left = -24
		flat = true
		toggle_mode = true
		connect("toggled", self, "on_toggled")
		icon = preload("res://assets/sort-desc.png")
		expand_icon = true
		
		
	func on_toggled(pressed : bool):
		ascending = pressed
		
		if ascending:
			icon = preload("res://assets/sort-asc.png")
		else:
			icon = preload("res://assets/sort-desc.png")
			
		emit_signal("sort_requested")
		

	
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
	header_row.add_child(RowElement.new("", header_color))
	for header in headers:
		var element = RowElement.new(header, header_color, true)
		element.align = Label.ALIGN_LEFT
		header_row.add_child(element)
		element.connect("sort_requested", self, "sort_by_column")
		
func add_row(data : Array):
	var row = HBoxContainer.new()
	row.set("custom_constants/separation", 2)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	for value in data:
		var color : Color
		if row.get_child_count() <= header_columns_count:
			color = column_header_color 
			if rows.get_child_count() % 2 == 1:
				color = color.darkened(0.3)
		else:
			color = row_color
			if rows.get_child_count() % 2 == 1:
				color = color.darkened(0.3)
		row.add_child(RowElement.new(str(value), color if row.get_child_count() > 0 else header_color))
	rows.add_child(row)
		
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

func set_data(data):
	if raw_data.size() > 0:
		raw_data.clear()
	
	clear_all()
	var headers : Array = data[0]["group"].keys()
	var vars : Array = data[0].keys()
	vars.remove(vars.find("group"))
	headers.append_array(vars)
	set_headers(headers)
	
	var i : int = 1
	for data_row in data:
		var data_array : Array = [" "]
		for key in data_row["group"]:
			data_array.append(data_row["group"][key])
			
		for key in data_row:
			if key == "group":
				continue
			data_array.append(data_row[key])
		
		raw_data.append(data_array)
		i += 1
		
	update_table()
		
func update_table():
	for data in raw_data:
		add_row(data)
		
	autoadjust_table()


func _on_Rows_resized():
	if is_instance_valid(rows):
		header_row.rect_size.x = rows.rect_size.x
		
func get_column_min_size(column : int):
	var size = -INF
	for row in rows.get_children():
		var cell = row.get_child(column)
		var cell_size = cell.get_min_size().x
		if size < cell_size:
			size = cell_size
			
	if column == 0:
		size = 8
	else:
		size = max(size, header_row.get_child(column).get_min_size().x + 24)
	
	return size
	
func set_column_size(column, size):
	for row in rows.get_children():
		var cell = row.get_child(column)
		cell.rect_min_size.x = size
		
	header_row.get_child(column).rect_min_size.x = size


func autoadjust_table():
	var columns = header_row.get_child_count()
	var total_size : float = 0.0
	var columns_sizes : Array = []
	for i in columns:
		columns_sizes.append(get_column_min_size(i))
		set_column_size(i, columns_sizes[i])
		total_size += columns_sizes[i] 
		
	if total_size == 0.0:
		return
	
	var container_width : float = scroll_container.rect_size.x
	
	if container_width > total_size:
		var ratio = (container_width - 2 * (header_row.get_child_count() - 1)) / total_size
		for i in columns:
			set_column_size(i, columns_sizes[i]*ratio)
			
	yield(VisualServer,"frame_post_draw")
	
	scroll_container.scroll_horizontal = container_width < total_size


func _on_TableWidget_resized():
	if is_instance_valid(header_row):
		autoadjust_table()
		

func sort_by_column(column : int, ascending : bool):
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
