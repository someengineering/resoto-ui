tool
extends BaseWidget

export (float) var x_origin := -100.0 setget set_x_origin
export (float) var x_range := 200.0 setget set_x_range
export (bool) var auto_x := true
export (float) var max_y_value := 100
export (float) var min_y_value := 0
export (bool) var x_axis_date := true
export (bool) var auto_scale := true
export (Vector2) var divisions := Vector2(3.0, 3.0)

export (Array, PoolVector2Array) var series

var dynamic_label_scene := preload("res://components/widgets/DynamicLabel.tscn")
var series_scene := preload("res://components/widgets/Serie.tscn")
var mouse_on_graph := false

var colors := [
	Color.aquamarine,
	Color.indianred,
	Color.dodgerblue,
	Color.khaki,
	Color.orchid,
	Color.slateblue
]

var current_color := 0

onready var graph_area := $GraphArea
onready var legend := $CanvasLayer/PopupLegend
onready var legend_container := $CanvasLayer/PopupLegend/VBoxContainer

func _ready():
	legend.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var data : PoolVector2Array = []
		data.resize(100)

		for i in data.size():
			data[i] = Vector2(i,2)

		clear_series()
		add_serie(data)
		
		for i in data.size():
			data[i] = Vector2(i,1+int(i/10))
		add_serie(data)
		
		for i in data.size():
			data[i] = Vector2(i,int(i/5))
		add_serie(data)
	if event is InputEventMouseMotion and mouse_on_graph and series.size() > 0:
		var x = x_range * graph_area.get_local_mouse_position().x / graph_area.rect_size.x + x_origin
		for label in legend_container.get_children():
			legend_container.remove_child(label)
			label.queue_free()
			
		var stacked = 0
		for i in series.size():
			var index = series.size() - i - 1
			var l := Label.new()
			var line : Line2D = graph_area.get_child(index)
			var closest_point = find_closest_at_x(x, series[index])
			
			l.text = line.name + ": " + str(closest_point.y)
			l.set("custom_colors/font_color", line.default_color)
			legend_container.add_child(l)
			legend.rect_global_position = get_global_mouse_position()
			closest_point.y += stacked
			stacked = closest_point.y
			line.show_indicator(transform_point(closest_point))
			


func set_x_origin(origin : float):
	x_origin = origin
	if is_inside_tree():
		update_series()
	
func set_x_range(r : float):
	x_range = r
	if is_inside_tree():
		update_series()

func _on_GraphArea_resized():
	update_series()
	var n = $XLabels.get_child_count()
	if n > 0:
		$XLabels.get_child(0).rect_min_size.x = $Grid.rect_size.x / divisions.x / 2
		$XLabels.get_child(n - 1).rect_min_size.x = $Grid.rect_size.x / divisions.x / 2
	$Grid.material.set_shader_param("size", $Grid.rect_size)
	
func update_series():
	if not is_instance_valid(graph_area):
		return
	if $GraphArea.rect_size.x == 0 or $GraphArea.rect_size.y == 0:
		return
	var origin : Vector2 = $GraphArea.rect_global_position + Vector2(0, $GraphArea.rect_size.y)
	var stacked : PoolVector2Array = []
	stacked.resize(series[0].size())
	stacked.fill(Vector2.ZERO)
	for i in $GraphArea.get_child_count():
		var index = $GraphArea.get_child_count() - i -1
		var line : Line2D = $GraphArea.get_child(index)
		var serie : PoolVector2Array = series[index]
		var values : PoolVector2Array = []
		for j in serie.size():
			var point = transform_point(serie[j]) + stacked[j]
			if $GraphArea.get_global_rect().grow(1).has_point(point + origin):
				values.append(point)
				stacked[j].y = point.y
				

		line.points = values
		line.global_position = origin

func update_graph_area():
	var nx = divisions.x
	var ny = divisions.y
	
	$Grid.material.set_shader_param("grid_divisions", divisions)
	
	var rsx : Vector2 = $XLabels.rect_size
	var rsy : Vector2 = $YLabels.rect_size
	
	for l in $XLabels.get_children():
		l.queue_free()
		
	var spacer := Control.new()
	spacer.rect_min_size.x = rsx.x / divisions.x / 2
	spacer.size_flags_horizontal = 0
	$XLabels.add_child(spacer)
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
		$XLabels.add_child(l)
	$XLabels.add_child(spacer.duplicate())
	for l in $YLabels.get_children():
		l.queue_free()
	for i in ny:
		var l = dynamic_label_scene.instance()
		l.max_font_size = 14
		l.min_font_size = 8
		l.text = str(int(max_y_value - (i+1)*(max_y_value - min_y_value) / ny))
		l.size_flags_vertical = SIZE_EXPAND_FILL
		l.align = Label.ALIGN_RIGHT
		l.valign = Label.VALIGN_BOTTOM
		$YLabels.add_child(l)
		
func add_serie(data : PoolVector2Array, color = null, serie_name := ""):
	var serie := series_scene.instance()
	$GraphArea.add_child(serie)
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
	for serie in $GraphArea.get_children():
		$GraphArea.remove_child(serie)
		serie.queue_free()
	
	series.clear()

func set_scale_from_series():
	var maxy = -INF
	var miny = INF
	
	var stacked := []
	stacked.resize(series[0].size())
	stacked.fill(0)
	for j in series.size():
		var serie = series[series.size() -j -1]
		for i in serie.size():
			var value = serie[i]
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
	var origin : Vector2 = $GraphArea.rect_global_position + Vector2(0, $GraphArea.rect_size.y)
	for line in $GraphArea.get_children():
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
