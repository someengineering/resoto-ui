extends BaseWidget

export (float) var x_origin := 0.0 setget set_x_origin
export (float) var x_range := 200.0 setget set_x_range
export (bool) var auto_x := true
export (float) var max_y_value := 100.0
export (float) var min_y_value := 0.0
export (bool) var x_axis_date := true
export (bool) var auto_scale := true
export (Vector2) var divisions := Vector2(3.0, 3.0)

export (Array, PoolVector2Array) var series : Array

var dynamic_label_scene := preload("res://components/elements/utility/dynamic_label.tscn")
var series_scene := preload("res://components/dashboard/widget_chart/widget_chart_serie.tscn")
var mouse_on_graph := false

var is_dirty:= false
var blur_image_active:= false
var force_update_graph_area:= false
var dirty_timer:= 0.0

var step := 144
var prev_origin : Vector2

var y_zero_position := 0.0;

var colors := [
	Color.aquamarine,
	Color.indianred,
	Color.dodgerblue,
	Color.khaki,
	Color.orchid,
	Color.slateblue
]

var current_color := 0

onready var graph_area := $Viewport/GridContainer/Grid/GraphArea
onready var legend := $CanvasLayer/PopupLegend
onready var legend_container := $CanvasLayer/PopupLegend/VBoxContainer
onready var legend_grid := $CanvasLayer/PopupLegend/VBoxContainer/GridContainer
onready var legend_time_label := $CanvasLayer/PopupLegend/VBoxContainer/TimeLabel
onready var x_labels := $Viewport/GridContainer/XLabels
onready var y_labels := $Viewport/GridContainer/YLabels
onready var grid := $Viewport/GridContainer/Grid
onready var legend_pos := $Grid/LegendPosition
onready var viewport := $Viewport
onready var update_blur := $UpdateBlur
onready var update_tween := $UpdateTween


func _ready() -> void:
	legend.visible = false
	if get_parent().get_parent() is WidgetContainer:
		get_parent().get_parent().connect("moved_or_resized", self, "_on_Grid_resized")
	_on_Grid_resized()
	hide()


func _input(event) -> void:
	if event is InputEventMouseMotion and mouse_on_graph and series.size() > 0:
		var x = x_range * graph_area.get_local_mouse_position().x / graph_area.rect_size.x
		legend.rect_global_position = get_global_mouse_position() + Vector2(24,0)
		legend.rect_size.y = 0
		
		for label in legend_grid.get_children():
			label.queue_free()
		
		var time_text : Array = Time.get_datetime_string_from_unix_time(int(x_origin+x)).left(16).split("T")
		legend_time_label.text = time_text[0] + "\nTime: %s" % time_text[1].trim_prefix("0")
		# First, grab all the values, set the indicator points, sum up the stacked value
		var stacked : float = 0.0
		var sorted_values : Array = []
		for i in series.size():
			var index = series.size() - i - 1
			var line : Line2D = graph_area.get_child(index)
			var closest_point = find_value_at_x(x, series[index])
			if str(closest_point.y) == "nan":
				continue
			sorted_values.append( [closest_point.y, line.name, line.default_color] )
			if line.get_meta("stack"):
				closest_point.y += stacked
				stacked = closest_point.y
			line.show_indicator(transform_point(closest_point))
			
		
		sorted_values.sort_custom(self, "sort_label_values")
		
		for sv in sorted_values:
			var l_variable := Label.new()
			var l_value := Label.new()
			l_variable.text = sv[1] + ":"
			l_value.text = str(sv[0])
			l_variable.set("custom_colors/font_color", sv[2])
			l_value.set("custom_colors/font_color", sv[2])
			legend_grid.add_child(l_variable)
			legend_grid.add_child(l_value)
		
		legend.visible = legend_grid.get_child_count() > 0


static func sort_label_values(a, b):
	return a[0] > b[0]


func set_x_origin(origin : float) -> void:
	x_origin = origin


func set_x_range(r : float) -> void:
	x_range = r


func _on_Grid_resized() -> void:
	if not is_instance_valid(x_labels):
		return
	viewport.size = rect_size
	$Viewport/GridContainer.rect_size = rect_size
	complete_update(false)


func update_series() -> void:
	if (series.empty()
	or not is_instance_valid(graph_area)
	or (graph_area.rect_size.x == 0 or graph_area.rect_size.y == 0)):
		return
	
	var origin : Vector2 = Vector2(grid.rect_global_position.x, grid.rect_global_position.y + graph_area.rect_size.y)
	var n = graph_area.get_child_count()
	var stacked : PoolRealArray = []
	stacked.resize(range(0, x_range, step).size())
	stacked.fill(0)

	for i in n:
		var index = n - i - 1
		var line : Line2D = graph_area.get_child(index)
		var values : PoolVector2Array = []
		
		for j in stacked.size():
			var point = find_value_at_x(j * step ,series[index])
			if str(point.y) == "nan":
				continue
				
			if line.get_meta("stack"):
				point.y += stacked[j]
				stacked[j] = point.y
			values.append(transform_point(point))
		line.points = values
		line.zero_position = transform_point(Vector2.ZERO).y
		line.global_position = origin


func update_graph_area(force := false) -> void:
	if not is_instance_valid(graph_area):
		return
	var new_divisions = (graph_area.rect_size / 100).snapped(Vector2.ONE)
	new_divisions.x = max(2, new_divisions.x)
	new_divisions.y = max(2, new_divisions.y)
	
	if divisions.x != new_divisions.x or force:
		divisions.x = new_divisions.x
		var nx = divisions.x
	
		for l in x_labels.get_children():
			x_labels.remove_child(l)
			l.queue_free()
		
		var dummy_label := Control.new()
		dummy_label.rect_min_size.x = x_labels.rect_size.x / nx / 2
		x_labels.add_child(dummy_label)
		
		for i in nx - 1:
			var l : DynamicLabel = dynamic_label_scene.instance()
			var x_value = int(x_origin + (i+1)*x_range / nx)
			if x_axis_date:
				x_value = Time.get_datetime_string_from_unix_time(x_value).replace("T", "\n")
			l.max_font_size = 18
			l.min_font_size = 12
			l.text = str(x_value)
			l.size_flags_horizontal = SIZE_EXPAND_FILL
			l.size_flags_vertical = 0
			l.valign = Label.VALIGN_TOP
			l.align = Label.ALIGN_CENTER
			x_labels.add_child(l)

		x_labels.add_child(dummy_label.duplicate())
		
	if divisions.y != new_divisions.y or force:
		divisions.y = new_divisions.y
		var ny = divisions.y
		for l in y_labels.get_children():
			l.queue_free()
			
		for i in ny:
			var l = dynamic_label_scene.instance()
			l.max_font_size = 14
			l.min_font_size = 10
			l.text = str(int(i*(max_y_value - min_y_value) / ny))
			l.align = Label.ALIGN_RIGHT
			l.valign = Label.VALIGN_CENTER
			l.rect_position.y = y_labels.rect_size.y * (y_zero_position - i/ny) - l.rect_size.y / 2
			l.anchor_right = 1
			l.margin_right = 0
			print(l.rect_position.y)
			y_labels.add_child(l)


func add_serie(data : PoolVector2Array, color = null, serie_name := "", stack := false) -> void:
	var serie := series_scene.instance()
	serie.set_meta("stack", stack)
	serie.get_node("Polygon2D").visible = stack
	graph_area.add_child(serie)
	serie.points = data
	series.append(data)
	
	if color != null:
		serie.default_color = color
	else:
		serie.default_color = colors[current_color]
		current_color = wrapi(current_color + 1, 0, colors.size())
		
	if serie_name == "":
		serie_name = "Serie %d" % series.size()
		
	serie.name = serie_name


func clear_series() -> void:
	for serie in graph_area.get_children():
		if serie is Line2D:
			graph_area.remove_child(serie)
			serie.queue_free()
	current_color = 0
	series.clear()

func set_scale_from_series() -> void:
	if series.size() == 0:
		return
	
	var maxy = -INF
	var miny = INF

	var stacked : PoolRealArray = []
	stacked.resize(range(0, x_range, step).size())
	stacked.fill(0)
	
	for j in stacked.size():
		for serie in series:
			var value = find_value_at_x(j*step, serie)
			if str(value.y) == "nan":
				continue
			if miny > value.y:
				miny = value.y
			if stacked:
				value.y += stacked[j]
				stacked[j] = value.y
			if maxy < value.y:
				maxy = value.y
	
	
	max_y_value = maxy + (maxy - miny) * 0.1 if maxy != miny else maxy * 1.1
	min_y_value = miny - (maxy - miny) * 0.1 if maxy != miny else miny * 0.9
	if miny == 0:
		min_y_value = 0
		
	y_zero_position = max_y_value / (max_y_value - min_y_value)
	print(y_zero_position)
	grid.material.set_shader_param("zero_position", y_zero_position)


func do_complete_update():
	if auto_scale:
		set_scale_from_series()
	update_series()
	update_graph_area(force_update_graph_area)
	
	var n = x_labels.get_child_count()
	if n > 0:
		x_labels.get_child(0).rect_min_size.x = grid.rect_size.x / divisions.x / 2
		x_labels.get_child(n - 1).rect_min_size.x = grid.rect_size.x / divisions.x / 2
	
	grid.material.set_shader_param("grid_divisions", divisions)
	grid.material.set_shader_param("size", grid.rect_size)
	
	legend_pos.rect_size = graph_area.rect_size
	force_update_graph_area = false
	is_dirty = false
	blur_image_active = false
	dirty_timer = 0.0
	update_tween.interpolate_property(update_blur.material, "shader_param/lod", 4, 0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.1)
	update_tween.interpolate_property(update_blur, "modulate:a", 1, 0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.1)
	update_tween.start()
	set_viewport_mode(false)
	show()


func set_viewport_mode(_update:bool):
	if _update:
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	else:
		viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME


func complete_update(_force_update_graph_area:bool=false):
	set_viewport_mode(true)
	dirty_timer = 0.0
	if _force_update_graph_area:
		force_update_graph_area = true
	is_dirty = true


func _on_Chart_resized():
	if not viewport:
		return
	if not blur_image_active:
		blur_image_active = true
		var img:Image = viewport.get_texture().get_data()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		var tex:ImageTexture = ImageTexture.new()
		tex.create_from_image(img)
		update_blur.texture = tex
		update_blur.show()
		update_tween.interpolate_property(update_blur.material, "shader_param/lod", 0, 4, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		update_tween.interpolate_property(update_blur, "modulate:a", 0, 1, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		update_tween.start()


func _process(_delta : float) -> void:
	if is_dirty:
		dirty_timer += _delta
		if dirty_timer > 0.2:
			do_complete_update()
	
	var origin : Vector2 = graph_area.rect_global_position + Vector2(0, graph_area.rect_size.y)
	
	if prev_origin != origin:
		prev_origin = origin
		for line in graph_area.get_children():
			if line is Line2D:
				line.global_position = origin
				
	legend_pos.rect_size = graph_area.rect_size
	legend_pos.rect_position = grid.rect_position


func find_closest_at_x(target_x : float, serie : PoolVector2Array) -> Vector2:
	var distance = INF
	var result = null
	
	for value in serie:
		var new_distance = abs(value.x - target_x)
		if new_distance > distance:
			break
		distance = new_distance
		result = value
		
	return result


func find_value_at_x(target_x : float, serie : PoolVector2Array) -> Vector2:
	var prev = null
	var next = null
	
	if target_x < serie[0].x or target_x > serie[serie.size() -1].x:
		return Vector2(target_x, NAN)
	
	for value in serie:
		if value.x == target_x:
			return value
		elif value.x < target_x:
			prev = value
		else:
			next = value
			break
	
	if prev == null or next == null:
		return Vector2(target_x, 0)
	else:
		return Vector2(target_x, lerp(prev.y, next.y ,(target_x - prev.x) / (next.x - prev.x)))


func _on_Grid_mouse_entered() -> void:
	for line in graph_area.get_children():
		line.indicator.visible = true
	mouse_on_graph = true
	set_viewport_mode(true)
	yield(VisualServer,"frame_post_draw")
	legend.visible = true


func _on_Grid_mouse_exited() -> void:
	for line in graph_area.get_children():
		line.indicator.visible = false
	legend.visible = false
	mouse_on_graph = false
	set_viewport_mode(false)


func transform_point(point : Vector2) -> Vector2:
	var ratio := Vector2(x_range / graph_area.rect_size.x,(max_y_value - min_y_value) / graph_area.rect_size.y)
	point = ((point + Vector2(0, -min_y_value)) / ratio)
	return Vector2(point.x, min(-point.y, -0.0001))


func get_csv(separator := ",", end_of_line := "\n") -> String:
	if series.size() <= 0:
		return ""
	
	var data : PoolStringArray = []
	var header : PoolStringArray = ["Date"]
	
	for line in graph_area.get_children():
		header.append(line.name)
	
	data.append(header.join(separator))
	
	for i in series[0].size():
		var row : PoolStringArray = []
		row.append(Time.get_datetime_string_from_unix_time(series[0][i].x + x_origin))
		for serie in series:
			row.append(serie[i].y)
			
		data.append(row.join(separator))
	
	return data.join(end_of_line)
