extends BaseWidget

var image : Image 

var data_array : Array = []
var x_categories : Array = []
var y_categories : Array = []


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
		
		for row in data:
			var x_category : String = row["group"][headers[1]]
			if not x_category in x_categories:
				x_categories.append(x_category)
				var label := preload("res://components/widgets/RotatedLabel.tscn").instance()
				
				$HBoxContainer.add_child(label)
				label.text = x_category
				label.size_flags_horizontal = SIZE_EXPAND_FILL
				
			var y_category : String = row["group"][headers[0]]
			if not y_category in y_categories:
				y_categories.append(y_category)
				var label := DynamicLabel.new()
				label.text = y_category
				label.clip_text = true
				label.hint_tooltip = y_category
				label.valign = Label.VALIGN_CENTER
				label.size_flags_vertical = SIZE_EXPAND_FILL
				label.autowrap = true
				$VBoxContainer.add_child(label)
				
		
		image.create(x_categories.size(), y_categories.size(), true, Image.FORMAT_RGBA8)
		image.lock()
		for row in data:
			var j = x_categories.find(row["group"][headers[1]])
			var i = y_categories.find(row["group"][headers[0]])
			
			var value = row[vars[0]]
			
			var color := Color.rebeccapurple * float(value) / 10.0
			color.a = 1.0;
			
			image.set_pixel(j, i, color)
		image.unlock()
		var texture := ImageTexture.new()
		texture.create_from_image(image, 0)
		$TextureRect.texture = texture
		
