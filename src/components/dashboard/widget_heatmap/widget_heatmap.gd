extends BaseWidget

var image : Image 

var x_categories : Array = []
var y_categories : Array = []

var gradient : Gradient = Gradient.new()

var value_matrix : Array
var heat_variable : String = ""
var min_value : float = 0.0
var max_value : float = 0.0
var current_data : Array = []

export (DynamicFont) var font
export (Color) var low_color := Color.midnightblue setget set_low_color
export (Color) var high_color := Color.orangered setget set_high_color

onready var grid := $TextureRect/Grid
onready var tooltip := $ToolTipLabel
onready var label_y := $LabelY
onready var label_x := $LabelX


func _ready():
	set_low_color(low_color)
	set_high_color(high_color)
	restore_gradient()
	set_process(false)


func _process(_delta):
	if current_data.empty():
		return
	update_highlighted_cell((grid.get_local_mouse_position() * Vector2(x_categories.size(), y_categories.size()) / grid.rect_size - Vector2(0.5,0.5)).snapped(Vector2.ONE))


func reset_highlighted_cell():
	grid.material.set_shader_param("highlighted_cell", Vector2(-1,-1))
	var vbox_children = $VBoxContainer.get_children()
	for label in vbox_children:
		label.modulate = Color.white
	var hbox_children = $HBoxContainer.get_children()
	for label in hbox_children:
		label.modulate = Color.white
	tooltip.hide()


func update_highlighted_cell(cell_position : Vector2):
	cell_position.x = max(0, cell_position.x)
	cell_position.y = max(0, cell_position.y)
	if cell_position.y > value_matrix.size()-1:
		return
	if cell_position.x > value_matrix[cell_position.y].size()-1:
		return
	
	grid.material.set_shader_param(
		"highlighted_cell",
		cell_position
	)
	
	var highlighted_y_label : String = ""
	var vbox_children = $VBoxContainer.get_children()
	for label in vbox_children:
		label.modulate = Color.white
		if vbox_children.find(label) == cell_position.y:
			label.modulate *= 1.5
			highlighted_y_label = label.get_child(0).raw_text
			
	
	var highlighted_x_label : String = ""
	var hbox_children = $HBoxContainer.get_children()
	for label in hbox_children:
		label.modulate = Color.white
		if hbox_children.find(label) == cell_position.x:
			label.modulate *= 1.5
			highlighted_x_label = label.get_child(0).raw_text
			
	var value = str(value_matrix[cell_position.y][cell_position.x])
	
	tooltip.visible = value != "nan"
	var tt_text = "[b]%s[/b]: %s\n[b]%s[/b]: %s\n[b]%s %s[/b]" % [
		label_y.text,
		highlighted_y_label,
		label_x.text,
		highlighted_x_label,
		str(value_matrix[cell_position.y][cell_position.x]),
		 heat_variable
		]
	set_tooltip_text(tt_text)
	tooltip.rect_global_position = get_global_mouse_position() + Vector2(12,0)
	tooltip.rect_size = Vector2.ONE


func set_tooltip_text(_text:String):
	tooltip.get_node("Text").set_bbcode(_text)


func set_low_color(new_color : Color):
	low_color = new_color
	$TextureRect/ColorRect.color = low_color.darkened(0.5)
	restore_gradient()


func set_high_color(new_color : Color):
	high_color = new_color
	restore_gradient()


func restore_gradient():
	for i in range(gradient.get_point_count()-1,0,-1):
		gradient.remove_point(i)
	gradient.set_color(0, low_color)
	gradient.add_point(1.0, high_color)
	update_map()
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.fill_from = Vector2(0,1)
	grad_tex.fill_to = Vector2(0,0)
	grad_tex.gradient = gradient
	$Gradient.texture = grad_tex


func set_data(data, type : int):
	# Check data for correct format:
	if typeof(data) != TYPE_ARRAY or data.empty():
		_g.emit_signal("add_toast", "Heatmap Widget error", "Data missing.", 1, self)
		return
	for d in data:
		if d.size() != 2:
			if d.size() < 2:
				_g.emit_signal("add_toast", "Heatmap Widget error", "Aggregation not correct. Required format:\naggregate(y, x: sum(1) as type): is(type))", 1, self)
				return
			elif d.size() > 2:
				_g.emit_signal("add_toast", "Heatmap Widget error", "Aggregation not correct. Required format:\naggregate(y, x: sum(1) as type): is(type))", 1, self)
				return
	if not data[0].has("group") or data[0].group.empty() or data[0].group.size() != 2:
		if data[0].group.size() < 2:
			for d in data:
				d.group["Missing second axis, add a second grouping\naggregate(y, x: sum(1) as type): is(type))"] = ""
		if data[0].group.size() > 2:
			_g.emit_signal("add_toast", "Heatmap Widget error", "Aggregation not correct. Required format:\naggregate(y, x: sum(1) as type): is(type))", 1, self)
			return
	
	current_data = data
	x_categories.clear()
	y_categories.clear()
	
	if type == DataSource.TYPES.AGGREGATE_SEARCH || type == DataSource.TYPES.TWO_ENTRIES_AGGREGATE:
		var headers : Array = data[0]["group"].keys()
		var vars : Array = data[0].keys()
		vars.remove(vars.find("group"))
		
		label_x.text = headers[1]
		label_y.text = headers[0]
		
		var hbox = $HBoxContainer
		for label in hbox.get_children():
			hbox.remove_child(label)
			label.queue_free()
		
		var vbox = $VBoxContainer
		for label in vbox.get_children():
			vbox.remove_child(label)
			label.queue_free()
			
		min_value = INF
		max_value = -INF
		heat_variable = vars[0]
		
		for row in data:
			var heat = -1.0
			if not str(row[heat_variable]).is_valid_float():
				heat = 0.0
			else:
				heat = float(row[heat_variable])
			if heat < min_value:
				min_value = row[heat_variable]

			if heat > max_value:
				max_value = row[heat_variable]
			
#			if row["group"][headers[1]] != null:
			if typeof(row["group"][headers[1]]) == TYPE_REAL:
				row["group"][headers[1]] = str(stepify(row["group"][headers[1]], 0.01))
			var x_category : String = str(row["group"][headers[1]])
			if not x_category in x_categories:
				x_categories.append(x_category)
				var label := ClippedLabel.new()
				var control := Control.new()
				
				control.add_child(label)
				control.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hbox.add_child(control)
				label.add_font_override("font", font)
				label.rect_rotation = 53
				label.anchor_right = 0.5
				label.anchor_left = 0.5
				label.margin_right = 0
				label.margin_left = 0
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				label.hint_tooltip = x_category
				label.rect_size.x = 90
				label.rect_position.x += 10
				control.size_flags_horizontal = SIZE_EXPAND_FILL
				
				label.raw_text = x_category
			
#			if row["group"][headers[0]] != null:
			if typeof(row["group"][headers[0]]) == TYPE_REAL:
				row["group"][headers[0]] = str(stepify(row["group"][headers[0]], 0.01))
			var y_category : String = str(row["group"][headers[0]])
			if not y_category in y_categories:
				y_categories.append(y_category)
				var label := preload("res://components/elements/utility/clipped_label.tscn").instance()
				var control := Control.new()
				
				vbox.add_child(control)
				control.add_child(label)
				control.rect_min_size = Vector2(0,0)
				
				label.hint_tooltip = y_category
				control.size_flags_vertical = SIZE_EXPAND_FILL
		
				label.add_font_override("font", font)
				label.valign = Label.VALIGN_CENTER
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				
				label.raw_text = y_category
		
		update_map()


func update_map():
	if x_categories.size() == 0 or y_categories.size() == 0:
		return
	image = Image.new()
	image.create(x_categories.size(), y_categories.size(), true, Image.FORMAT_RGBA8)
	image.lock()
	
	$Gradient/Low.text = str(min_value)
	$Gradient/High.text = str(max_value)
	
	value_matrix = []
	value_matrix.resize(y_categories.size())
	
	for i in y_categories.size():
		var data_row : Array = []
		data_row.resize(x_categories.size())
		data_row.fill(NAN)
		value_matrix[i] = data_row
	
	for row in current_data:
		var j : int = int(max(x_categories.find(str(row["group"][label_x.text])), 0))
		var i : int = int(max(y_categories.find(str(row["group"][label_y.text])), 0))
		
		var value = row[heat_variable]
		
		value_matrix[i][j] = value
		
		var color := high_color
		if max_value != min_value:
			color = gradient.interpolate((value - min_value)/(max_value - min_value))

		color.a = 1.0;
		image.set_pixel(j, i, color)
		
	image.unlock()
	var grid_material = grid.material
	grid_material.set_shader_param("grid_count", image.get_size())

	var texture := ImageTexture.new()
	texture.create_from_image(image, 0)
	$TextureRect.texture = texture


func _on_Grid_mouse_entered():
	set_process(true)


func _on_Grid_mouse_exited():
	reset_highlighted_cell()
	set_process(false)


func _get_property_list() -> Array:
	var properties = []
	
	properties.append({
		name = "Widget Settings",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	properties.append({
		"name" : "low_color",
		"type" : TYPE_COLOR
	})
	
	properties.append({
		"name" : "high_color",
		"type" : TYPE_COLOR
	})
	
	return properties
