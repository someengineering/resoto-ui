extends Control

const TREEMAP_ELEMENT = preload("res://ui/elements/Element_TreeMap_Box.tscn")

signal pressed

export(Gradient) var gradient
export(Vector2) var treemap_size := Vector2(600, 600)

var active_request: ResotoAPI.Request
var treemap_size_temp := treemap_size
var datasets := []

var start: int = 0
var end: int = 0
var offset := Vector2.ZERO
var is_vert: bool = aspect_vertical(treemap_size_temp)
var aspect_current: float = 9999999999999.0
var aspect_last: float = 0.0

var fake_data: Dictionary = {
	"example_1": 1035,
	"example_2": 8341,
	"example_3": 11682,
	"example_4": 17034,
	"example_5": 492,
	"example_6": 1657,
	"example_7": 7012,
	"example_8": 528,
	"example_9": 22467,
	"example_10": 0,
	"example_11": 5290
}


class Dataset:
	var ds_id = ""
	var ds_name = ""
	var ds_is_zero := false
	var ds_value_temp = 0.0
	var ds_displaysize := Vector2.ZERO
	var ds_displaysize_temp := Vector2.ZERO
	var ds_displaypos := Vector2.ZERO
	var ds_value = 0.0
	var ds_scaled_value = 0.0
	var ds_color := Color.white
	var ds_box: Object = null


func _ready():
	get_tree().root.connect("size_changed", self, "on_ui_shrink_changed")
	_g.connect("ui_shrink_changed", self, "on_ui_shrink_changed")


# For debugging and testing
func _on_Button_pressed():
	$Button.hide()
	get_treemap_from_api("nPAI722a3j5V_D_s0dLObg")


func set_treemap_size():
	treemap_size = rect_size.round()
	treemap_size.x = max(300, treemap_size.x)
	treemap_size.y = max(300, treemap_size.y)
	treemap_size_temp = treemap_size
	is_vert = aspect_vertical(treemap_size_temp)


func get_treemap_from_api(node_id:String):
	clear_treemap()
	var search_command = "id(" + node_id + ") limit 1"
	active_request = API.graph_search(search_command, self, "list")


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Search", Utils.err_enum_to_string(error) + "\nBody: "+ active_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		var response = _response.transformed.result[0]
		
		if (response.empty()
		or not response.has("metadata")
		or not response.metadata.has("descendant_summary")):
			return
		var account_dict:= {}
		for key in response.metadata.descendant_summary:
			account_dict[key] = response.metadata.descendant_summary[key]

		create_treemap(account_dict)


func clear_treemap():
	for d in datasets:
		d.ds_box.queue_free()
	datasets.clear()
	start = 0
	end = 0
	treemap_size_temp = treemap_size
	offset = Vector2.ZERO

func reset_boxes():
	for d in datasets:
		d.ds_displaysize = Vector2.ZERO
		d.ds_displaysize_temp = Vector2.ZERO
		d.ds_displaypos = Vector2.ZERO


func create_treemap(_data: Dictionary):
	set_treemap_size()
	create_dataset_from_dict(_data)
	calc_map()
	fix_map()
	add_visuals()


func update_treemap():
	start = 0
	end = 0
	offset = Vector2.ZERO
	aspect_current = 9999999999999
	aspect_last = 0
	set_treemap_size()
	reset_boxes()
	calc_map()
	fix_map()
	update_visuals()


func fix_map():
	for box in datasets:
		var pos_diff = box.ds_displaypos - box.ds_displaypos.round()
		box.ds_displaypos = box.ds_displaypos.round()
		box.ds_displaysize += pos_diff
		box.ds_displaysize = box.ds_displaysize.round()
		var edge_pos = box.ds_displaypos + box.ds_displaysize
		if edge_pos.x >= treemap_size.x - 2:
			box.ds_displaysize.x = treemap_size.x - box.ds_displaypos.x
		if edge_pos.y >= treemap_size.y - 2:
			box.ds_displaysize.y = treemap_size.y - box.ds_displaypos.y


func create_dataset_from_dict(_data: Dictionary):
	var _data_keys = _data.keys()
	for i in _data.size():
		var _key = _data_keys[i]
		var new_dataset = Dataset.new()
		new_dataset.ds_id = str(i)
		new_dataset.ds_name = _key
		if _data[_key] <= 0:
			new_dataset.ds_is_zero = true
		new_dataset.ds_value = _data[_key]
		new_dataset.ds_value_temp = _data[_key]
		datasets.append(new_dataset)
	datasets.sort_custom(self, "sort_desc")


func update_visuals():
	for d in datasets:
		var new_element = d.ds_box
		new_element.rect_position = d.ds_displaypos
		new_element.rect_size = d.ds_displaysize
		new_element.final_size = d.ds_displaysize
		new_element.update_label_pos()


func add_visuals():
	var time_delay = 0.0
	var tween = $Tween
	for d in datasets:
		var new_element = TREEMAP_ELEMENT.instance()
		new_element.rect_position = d.ds_displaypos
		new_element.rect_size = Vector2.ZERO
		new_element.final_size = d.ds_displaysize
		new_element.element_color = d.ds_color
		new_element.label = d.ds_name
		new_element.value = d.ds_value if !d.ds_is_zero else 0
		new_element.connect("pressed", self, "_on_treemap_element_pressed", [d.ds_name])
		new_element.show()
		d.ds_box = new_element
		add_child(new_element)
		
		time_delay += 0.01
		new_element.modulate.a = 0
		tween.interpolate_property(
			new_element,
			"rect_size",
			Vector2.ZERO,
			new_element.final_size,
			0.2,
			Tween.TRANS_EXPO,
			Tween.EASE_OUT,
			time_delay
		)
		tween.interpolate_property(
			new_element,
			"modulate",
			Color.transparent,
			Color(2, 2, 2, 1),
			0.2,
			Tween.TRANS_EXPO,
			Tween.EASE_OUT,
			time_delay
		)
		tween.interpolate_property(
			new_element,
			"modulate",
			Color(2, 2, 2, 1),
			Color.white,
			1.0,
			Tween.TRANS_EXPO,
			Tween.EASE_OUT,
			time_delay + 0.2
		)
	tween.start()


func calc_map():
	var value_scale := 0.0
	var value_total := 0.0

	var values_in_dataset := []
	for d in datasets:
		if d.ds_value_temp == 0:
			continue
		value_total += d.ds_value_temp
		values_in_dataset.append(d.ds_value_temp)

	if values_in_dataset.empty():
		return
	var smallest_value = float( values_in_dataset.min() )
	var biggest_value = float( values_in_dataset.max() )
	
	var zero_value = max(smallest_value/4, 1)
  
	for d in datasets:
		if d.ds_is_zero:
			d.ds_value_temp = zero_value
			d.ds_value = zero_value
			value_total += zero_value
	value_scale = ((treemap_size.x * treemap_size.y) / value_total) / 10

	for d in datasets:
		d.ds_value_temp *= value_scale
		d.ds_scaled_value = range_lerp(d.ds_value, smallest_value, biggest_value, 0, 1)
		d.ds_color = gradient.interpolate(d.ds_scaled_value)

	find_best_aspect()

	datasets[-1].ds_displaypos = offset


func find_best_aspect():
	while end < datasets.size():
		aspect_last = try(start, end, is_vert)
		if aspect_last > aspect_current or aspect_last < 1:
			var size_current := Vector2.ZERO

			for i in range(start, end + 1):
				datasets[i].ds_displaypos = size_current + offset
				size_current += (
					Vector2(0, datasets[i].ds_displaysize.y)
					if is_vert
					else Vector2(datasets[i].ds_displaysize.x, 0)
				)

			offset += (
				Vector2(datasets[start].ds_displaysize.x, 0)
				if is_vert
				else Vector2(0, datasets[start].ds_displaysize.y)
			)

			treemap_size_temp = treemap_size - offset
			is_vert = aspect_vertical(treemap_size_temp)
			start = end
			end = start
			aspect_current = 9999999999999
			find_best_aspect()
		else:
			for i in range(start, end + 1):
				#if datasets[i].ds_is_zero:
				#	fit_zero_value_boxes(i)
				#	end = datasets.size()
				#	break
				datasets[i].ds_displaysize = datasets[i].ds_displaysize_temp
			aspect_current = aspect_last

		end += 1


func try(_start: int, _end: int, vertical: bool) -> float:
	var total := 0.0
	var aspect := 0.0
	var local_size := Vector2.ZERO

	for i in range(_start, _end + 1):
		total += datasets[i].ds_value_temp

	local_size = (
		Vector2(total / treemap_size_temp.y * 10, treemap_size_temp.y)
		if vertical
		else Vector2(treemap_size_temp.x, total / treemap_size_temp.x * 10)
	)  #.round()

	for i in range(_start, _end + 1):
		if i > datasets.size():
			break

		if vertical:
			datasets[i].ds_displaysize_temp = Vector2(
				local_size.x, local_size.y * (datasets[i].ds_value_temp / total)
			)  #.round()
		else:
			datasets[i].ds_displaysize_temp = Vector2(
				local_size.x * (datasets[i].ds_value_temp / total), local_size.y
			)  #.round()

		datasets[i].ds_displaysize_temp.x = max(datasets[i].ds_displaysize_temp.x, 1)
		datasets[i].ds_displaysize_temp.y = max(datasets[i].ds_displaysize_temp.y, 1)

		aspect = max(
			datasets[i].ds_displaysize_temp.y / datasets[i].ds_displaysize_temp.x,
			datasets[i].ds_displaysize_temp.x / datasets[i].ds_displaysize_temp.y
		)

	return aspect


func aspect_vertical(size: Vector2) -> bool:
	return size.x > size.y


func sort_desc(a, b) -> bool:
	if a.ds_value > b.ds_value:
		return true
	else:
		return false

func on_ui_shrink_changed():
	yield(VisualServer, "frame_post_draw")
	if not datasets.empty():
		update_treemap()


func _on_treemap_element_pressed(kind:String):
	emit_signal("pressed", kind)
