tool
extends BaseWidget

export (float) var x_origin := -100.0 setget set_x_origin
export (float) var x_range := 200.0 setget set_x_range
export (bool) var auto_x := true
export (float) var max_y_value := 0
export (float) var min_y_value := -100.0
export (bool) var x_axis_date := true

export (Array, PoolVector2Array) var series := []

var dynamic_label_scene := preload("res://components/widgets/DynamicLabel.tscn")
var series_scene := preload("res://components/widgets/Serie.tscn")

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
onready var x_axis := $XAxis
onready var y_axis := $YAxis

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var data : PoolVector2Array = []
		data.resize(100)

		for i in data.size():
			data[i] = Vector2(i,i)

		clear_series()
		add_serie(data)
	

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
	update_graph_area()
	
func update_series():
	if $GraphArea.rect_size.x == 0 or $GraphArea.rect_size.y == 0:
		return
	var ratio := Vector2(x_range / $GraphArea.rect_size.x,(max_y_value - min_y_value) / $XAxis.rect_size.y)
	var origin : Vector2 = $GraphArea.rect_global_position + Vector2(0, $GraphArea.rect_size.y)
	for i in $GraphArea.get_child_count():
		var line : Line2D = $GraphArea.get_child(i)
		var serie : PoolVector2Array = series[i]
		var values : PoolVector2Array = []
		for point in serie:
			point += Vector2(-x_origin, -min_y_value)
			point /= ratio
			point.y *= -1
			if point.y >= 0.0:
				point.y = -0.0001
			if $GraphArea.get_global_rect().grow(1).has_point(point + origin):
				values.append(point)

		line.points = values
		line.global_position = origin

func update_graph_area():
	var nx : int = $XAxis.get_child_count()
	var ny : int = $YAxis.get_child_count()
	var rsx : Vector2 = $XLabels.rect_size
	var rsy : Vector2 = $YLabels.rect_size
	
	var label : DynamicLabel = dynamic_label_scene.instance()
	for l in $XLabels.get_children():
		l.queue_free()
	for i in nx:
		var l = label.duplicate()
		var x_value = int(x_origin + i*x_range / nx)
		if x_axis_date:
			x_value = Time.get_datetime_string_from_unix_time(x_value).replace("T", "\n")
		l.text = str(x_value)
		l.size_flags_horizontal = 3
		l.grow_horizontal = 2
		l.align = Label.ALIGN_CENTER
		l.valign = Label.ALIGN_CENTER
		l.rect_size.x = rsx.x/nx
		l.rect_size.y = rsx.y
		l.rect_position = $XAxis.get_child(i).rect_position - Vector2(rsx.x/nx/2,0)
		$XLabels.add_child(l)
	
	label = dynamic_label_scene.instance()
	for l in $YLabels.get_children():
		l.queue_free()
	for i in ny:
		var l = label.duplicate()
		l.text = str(int(max_y_value - (i+1)*(max_y_value - min_y_value) / ny))
		l.size_flags_horizontal = 3
		l.grow_horizontal = 2
		l.align = Label.ALIGN_CENTER
		l.valign = Label.ALIGN_CENTER
		l.rect_size.x = rsy.x
		l.rect_size.y = rsy.y/ny
		l.rect_position = $YAxis.get_child(i).rect_position - Vector2(0, rsy.y / ny / 2)
		$YLabels.add_child(l)
		
func add_serie(data : PoolVector2Array, color = null):
	var serie := series_scene.instance()
	$GraphArea.add_child(serie)
	serie.points = data
	print(data)
	series.append(data)
	update_series()
	update_graph_area()
	
	if color != null:
		serie.default_color = color
	else:
		serie.default_color = colors[current_color]
		current_color = wrapi(current_color + 1, 0, colors.size())
		print(current_color)
		print(colors[current_color])
	
func clear_series():
	for serie in $GraphArea.get_children():
		$GraphArea.remove_child(serie)
		serie.queue_free()
	series.clear()


func _process(_delta):
	var origin : Vector2 = $GraphArea.rect_global_position + Vector2(0, $GraphArea.rect_size.y)
	for line in $GraphArea.get_children():
		line.global_position = origin
