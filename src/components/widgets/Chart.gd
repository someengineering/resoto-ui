tool
extends BaseWidget

export (float) var x_origin := -100.0 setget set_x_origin
export (float) var x_range := 200.0 setget set_x_range
export (bool) var auto_x := true
export (float) var max_y_value := 100.0
export (float) var min_y_value := 0.0
export (bool) var x_axis_date := true
export (bool) var auto_scale := true
export (Vector2) var divisions := Vector2(3.0, 3.0)

export (Array, PoolVector2Array) var series : Array

var dynamic_label_scene := preload("res://components/widgets/DynamicLabel.tscn")
var series_scene := preload("res://components/widgets/Serie.tscn")
var mouse_on_graph := false

var previous_closest_index := 0

var colors := [
	Color.aquamarine,
	Color.indianred,
	Color.dodgerblue,
	Color.khaki,
	Color.orchid,
	Color.slateblue
]

var current_color := 0

onready var graph_area := $GridContainer/Grid/GraphArea
onready var legend := $CanvasLayer/PopupLegend
onready var legend_container := $CanvasLayer/PopupLegend/VBoxContainer
onready var x_labels := $GridContainer/XLabels
onready var y_labels := $GridContainer/YLabels
onready var grid := $GridContainer/Grid

func _ready():
	legend.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var data : PoolVector2Array = []
		data.resize(100)

		for i in data.size():
			data[i] = Vector2(i+10,2)

		clear_series()
		add_serie(data, null, "", true)

		for i in data.size():
			data[i] = Vector2(i+10,1+int(i/10))
		add_serie(data, null, "", true)

		for i in data.size():
			data[i] = Vector2(i+10,int(i/5))
		add_serie(data, null, "", true)
	if event is InputEventMouseMotion and mouse_on_graph and series.size() > 0:
		var x = x_range * graph_area.get_local_mouse_position().x / graph_area.rect_size.x + x_origin
		
		legend.rect_global_position = get_global_mouse_position()
		
		var closest_index = series[0].find(find_closest_at_x(x, series[0]))
		if previous_closest_index == closest_index:
			return
			
		var stacked = 0
		previous_closest_index = closest_index
		for label in legend_container.get_children():
			legend_container.remove_child(label)
			label.queue_free()
		
		for i in series.size():
			var index = series.size() - i - 1
			var l := Label.new()
			var line : Line2D = graph_area.get_child(index)
			var closest_point = series[index][closest_index]
			
			l.text = line.name + ": " + str(closest_point.y)
			l.set_meta("value", closest_point.y)
			l.set("custom_colors/font_color", line.default_color)
			
			legend_container.add_child(l)
			if line.get_meta("stack"):
				closest_point.y += stacked
				stacked = closest_point.y
			line.show_indicator(transform_point(closest_point))
		
		# Sort labels
		for i in legend_container.get_child_count():
			for j in range(i+1, legend_container.get_child_count()):
				if legend_container.get_child(i).get_meta("value") < legend_container.get_child(j).get_meta("value"):
					var label = legend_container.get_child(i)
					legend_container.move_child(legend_container.get_child(j), i)
					legend_container.move_child(label, j)

func set_x_origin(origin : float):
	x_origin = origin
	if is_inside_tree():
		update_series()
	
func set_x_range(r : float):
	x_range = r
	if is_inside_tree():
		update_series()

func _on_GraphArea_resized():
	if not is_instance_valid(x_labels):
		return
	var n = x_labels.get_child_count()
	if n > 0:
		x_labels.get_child(0).rect_min_size.x = grid.rect_size.x / divisions.x / 2
		x_labels.get_child(n - 1).rect_min_size.x = grid.rect_size.x / divisions.x / 2
	grid.material.set_shader_param("size", grid.rect_size)
	update_series()
	yield(VisualServer,"frame_post_draw")
	update_graph_area()
	
func update_series():
	if not is_instance_valid(graph_area):
		return
	if graph_area.rect_size.x == 0 or graph_area.rect_size.y == 0:
		return
	if series.size() == 0:
		return
	var origin : Vector2 = graph_area.rect_global_position + Vector2(0, graph_area.rect_size.y)
	var stacked : PoolVector2Array = []
	stacked.resize(series[0].size())
	stacked.fill(Vector2.ZERO)
	for i in graph_area.get_child_count():
		var index = graph_area.get_child_count() - i -1
		var line : Line2D = graph_area.get_child(index)
		var serie : PoolVector2Array = series[index]
		var values : PoolVector2Array = []
		for j in serie.size():
			var point = transform_point(serie[j])
			if line.get_meta("stack"):
				point += stacked[j]
			if graph_area.get_global_rect().grow(1).has_point(point + origin):
				values.append(point)
				if line.get_meta("stack"):
					stacked[j].y = point.y
				
		line.points = values
		line.global_position = origin

func update_graph_area():
	if not is_instance_valid(graph_area):
		return
		
	var new_divisions = (graph_area.rect_size / 100).snapped(Vector2.ONE)
	new_divisions.x = max(2, new_divisions.x)
	new_divisions.y = max(2, new_divisions.y)

	grid.material.set_shader_param("grid_divisions", divisions)
	
	if divisions.x != new_divisions.x:
		divisions.x = new_divisions.x
		var nx = divisions.x
	
		for l in x_labels.get_children():
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
			l.min_font_size = 8
			l.text = str(x_value)
			l.size_flags_horizontal = SIZE_EXPAND_FILL
			l.size_flags_vertical = 0
			l.valign = Label.VALIGN_TOP
			l.align = Label.ALIGN_CENTER
			x_labels.add_child(l)

		x_labels.add_child(dummy_label.duplicate())
		
	if divisions.y != new_divisions.y:
		divisions.y = new_divisions.y
		var ny = divisions.y
		for l in y_labels.get_children():
			l.queue_free()
			
		for i in ny:
			var l = dynamic_label_scene.instance()
			l.max_font_size = 14
			l.min_font_size = 10
			l.text = str(int(max_y_value - (i+1)*(max_y_value - min_y_value) / ny))
			l.size_flags_vertical = SIZE_EXPAND_FILL
			l.align = Label.ALIGN_RIGHT
			l.valign = Label.VALIGN_BOTTOM
			y_labels.add_child(l)
		
func add_serie(data : PoolVector2Array, color = null, serie_name := "", stack := false):
	var serie := series_scene.instance()
	serie.set_meta("stack", stack)
	serie.get_node("Polygon2D").visible = stack
	graph_area.add_child(serie)
	serie.points = data
	series.append(data)
	complete_update()
	
	if color != null:
		serie.default_color = color
	else:
		serie.default_color = colors[current_color]
		current_color = wrapi(current_color + 1, 0, colors.size())
		
	if serie_name == "":
		serie_name = "Serie %d" % series.size()
		
	serie.name = serie_name
	
	
func clear_series():
	for serie in graph_area.get_children():
		if serie is Line2D:
			graph_area.remove_child(serie)
			serie.queue_free()
	
	series.clear()

func set_scale_from_series():
	
	if series.size() == 0:
		return
	
	var maxy = -INF
	var miny = INF
	
	var stacked := []
	
	stacked.resize(series[0].size())
	stacked.fill(0)
	for j in series.size():
		var index = series.size() -j -1
		var serie = series[index]
		var line = graph_area.get_child(index)
		for i in serie.size():
			var value = serie[i]
			if line.get_meta("stack"):
				value.y += stacked[i]
				stacked[i] = value.y
			if maxy < value.y:
				maxy = value.y
			if miny > value.y:
				miny = value.y
				
	if maxy == -INF:
		maxy = 100
	if miny == INF:
		miny = 0
	max_y_value = maxy * 1.2
	
func _process(_delta):
	var origin : Vector2 = graph_area.rect_global_position + Vector2(0, graph_area.rect_size.y)
	for line in graph_area.get_children():
		if line is Line2D:
			line.global_position = origin


func complete_update():
	if auto_scale:
		set_scale_from_series()
	update_series()
	update_graph_area()
	
	
func find_closest_at_x(target_x, serie):

	var distance = INF
	var result = null
	
	for value in serie:
		var new_distance = abs(value.x - target_x)
		if new_distance > distance:
			break
		distance = new_distance
		result = value
		
	return result


func _on_GraphArea_mouse_entered():
	for line in graph_area.get_children():
		line.indicator.visible = true
	legend.visible = true
	mouse_on_graph = true


func _on_GraphArea_mouse_exited():
	for line in graph_area.get_children():
		line.indicator.visible = false
	legend.visible = false
	mouse_on_graph = false

func transform_point(point : Vector2):
	var ratio := Vector2(x_range / graph_area.rect_size.x,(max_y_value - min_y_value) / graph_area.rect_size.y)
	point += Vector2(-x_origin, -min_y_value)
	point /= ratio
	point.y *= -1
	if point.y >= 0.0:
		point.y = -0.0001
	return point

