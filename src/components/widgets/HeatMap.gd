extends BaseWidget

var image : Image 

var data_array : Array = []
var x_categories : Array = []
var y_categories : Array = []

var gradient : Gradient = Gradient.new()

export (DynamicFont) var font
export (Color) var low_color := Color.midnightblue setget set_low_color
export (Color) var high_color := Color.orangered setget set_high_color

func _ready():
	set_low_color(low_color)
	set_high_color(high_color)
	restore_gradient()
	
func _process(delta):
	var cell : Vector2 = ($TextureRect/Grid.get_local_mouse_position() * Vector2(x_categories.size(), y_categories.size()) / $TextureRect/Grid.rect_size - Vector2(0.5,0.5)).snapped(Vector2.ONE)
	$TextureRect/Grid.material.set_shader_param(
		"highlighted_cell",
		cell
	)
	
	for label in $VBoxContainer.get_children():
		label.modulate = Color.white
		if $VBoxContainer.get_children().find(label) == cell.y:
			label.modulate *= 1.5
			
	for label in $HBoxContainer.get_children():
		label.modulate = Color.white
		if $HBoxContainer.get_children().find(label) == cell.x:
			label.modulate *= 1.5
	

func set_low_color(new_color : Color):
	low_color = new_color
	$TextureRect/ColorRect.color = low_color.darkened(0.5)

func set_high_color(new_color : Color):
	high_color = new_color
	
func restore_gradient():
	for i in range(gradient.get_point_count()-1,0,-1):
		gradient.remove_point(i)
	gradient.set_color(0, low_color)
	gradient.add_point(1.0, high_color)
	
	$Gradient.texture = GradientTexture2D.new()
	$Gradient.texture.fill_from = Vector2(0,1)
	$Gradient.texture.fill_to = Vector2(0,0)
	$Gradient.texture.gradient = gradient

func set_data(data, type : int):
	data_array.clear()
	x_categories.clear()
	y_categories.clear()
	
	image = Image.new()
	
	if type == DataSource.TYPES.AGGREGATE_SEARCH:
		var headers : Array = data[0]["group"].keys()
		var vars : Array = data[0].keys()
		vars.remove(vars.find("group"))
		
		$LabelX.text = headers[1]
		$LabelY.text = headers[0]
		
		for label in $HBoxContainer.get_children():
			$HBoxContainer.remove_child(label)
			label.queue_free()
			
		for label in $VBoxContainer.get_children():
			$VBoxContainer.remove_child(label)
			label.queue_free()
			
		var min_value := INF
		var max_value := -INF
		
		for row in data:
			
			if float(row[vars[0]]) < min_value:
				min_value = row[vars[0]]

			if float(row[vars[0]]) > max_value:
				max_value = row[vars[0]]
			
			var x_category : String = row["group"][headers[1]]
			if not x_category in x_categories:
				x_categories.append(x_category)
				var label := ClippedLabel.new()
				var control := Control.new()
				
				control.add_child(label)
				control.mouse_filter = Control.MOUSE_FILTER_IGNORE
				$HBoxContainer.add_child(control)
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
				
			var y_category : String = row["group"][headers[0]]
			if not y_category in y_categories:
				y_categories.append(y_category)
				var label := ClippedLabel.new()
				var control := Control.new()
				
				$VBoxContainer.add_child(control)
				control.add_child(label)
				
				label.add_font_override("font", font)
				label.hint_tooltip = y_category
				label.valign = Label.VALIGN_CENTER
				control.size_flags_vertical = SIZE_EXPAND_FILL
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				label.anchor_bottom = 1
				label.anchor_right = 1
				label.anchor_top = 0
				label.margin_bottom = 0
				label.margin_top = 0
				label.rect_size.x = 70
				label.raw_text = y_category
				
		
		image.create(x_categories.size(), y_categories.size(), true, Image.FORMAT_RGBA8)
		image.lock()
		
		$Gradient/Low.text = str(min_value)
		$Gradient/High.text = str(max_value)
		
		for row in data:
			var j = x_categories.find(row["group"][headers[1]])
			var i = y_categories.find(row["group"][headers[0]])
			
			var value = row[vars[0]]
			
			var color := high_color
			if max_value != min_value:
				color = gradient.interpolate((value - min_value)/(max_value - min_value))

			color.a = 1.0;
			
			image.set_pixel(j, i, color)
		image.unlock()
		var grid_material = $TextureRect/Grid.material
		grid_material.set_shader_param("grid_count", image.get_size())

		var texture := ImageTexture.new()
		texture.create_from_image(image, 0)
		$TextureRect.texture = texture
		
