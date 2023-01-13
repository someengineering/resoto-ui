extends BaseWidget

var initial_world_speed := 0.0
var world_speed := initial_world_speed

var mouse_pressed : bool = false
var max_value : float = 0.0

const regions := {
	"gcp": {
		"us-west1": {
			"short_name": "us-west1",
			"long_name": "Oregon",
			"latitude": 45.6015056,
			"longitude": -121.1841587
		},
		"us-west2": {
			"short_name": "us-west2",
			"long_name": "Los Angeles",
			"latitude": 34.0536909,
			"longitude": -118.242766
		},
		"us-west3": {
			"short_name": "us-west3",
			"long_name": "Salt Lake City",
			"latitude": 40.7596198,
			"longitude": -111.8867975
		},
		"us-west4": {
			"short_name": "us-west4",
			"long_name": "Las Vegas",
			"latitude": 36.1672559,
			"longitude": -115.148516
		},
		"us-central1": {
			"short_name": "us-central1",
			"long_name": "Iowa",
			"latitude": 41.258841,
			"longitude": -95.8519484
		},
		"us-east1": {
			"short_name": "us-east1",
			"long_name": "South Carolina",
			"latitude": 33.1960027,
			"longitude": -80.0131374
		},
		"us-east4": {
			"short_name": "us-east4",
			"long_name": "N. Virginia",
			"latitude": 39.030019100000004,
			"longitude": -77.46964646557657
		},
		"us-east5": {
			"short_name": "us-east5",
			"long_name": "Columbus",
			"latitude": 39.9622601,
			"longitude": -83.0007065
		},
		"us-south1": {
			"short_name": "us-south1",
			"long_name": "Dallas",
			"latitude": 32.7762719,
			"longitude": -96.7968559
		},
		"northamerica-northeast1": {
			"short_name": "northamerica-northeast1",
			"long_name": "Montr\\u00e9al",
			"latitude": 45.5031824,
			"longitude": -73.5698065
		},
		"northamerica-northeast2": {
			"short_name": "northamerica-northeast2",
			"long_name": "Toronto",
			"latitude": 43.6534817,
			"longitude": -79.3839347
		},
		"southamerica-west1": {
			"short_name": "southamerica-west1",
			"long_name": "Santiago",
			"latitude": -33.4377756,
			"longitude": -70.6504502
		},
		"southamerica-east1": {
			"short_name": "southamerica-east1",
			"long_name": "S\\u00e3o Paulo",
			"latitude": -23.5506507,
			"longitude": -46.6333824
		},
		"europe-west2": {
			"short_name": "europe-west2",
			"long_name": "London",
			"latitude": 51.5073219,
			"longitude": -0.1276474
		},
		"europe-west1": {
			"short_name": "europe-west1",
			"long_name": "Belgium",
			"latitude": 50.4477484,
			"longitude": 3.8195241
		},
		"europe-west4": {
			"short_name": "europe-west4",
			"long_name": "Netherlands",
			"latitude": 53.44847365,
			"longitude": 6.849962720298231
		},
		"europe-west6": {
			"short_name": "europe-west6",
			"long_name": "Zurich",
			"latitude": 47.3744489,
			"longitude": 8.5410422
		},
		"europe-west3": {
			"short_name": "europe-west3",
			"long_name": "Frankfurt",
			"latitude": 50.1106444,
			"longitude": 8.6820917
		},
		"europe-north1": {
			"short_name": "europe-north1",
			"long_name": "Finland",
			"latitude": 60.5688901,
			"longitude": 27.1881877
		},
		"europe-central2": {
			"short_name": "europe-central2",
			"long_name": "Warsaw",
			"latitude": 52.2319581,
			"longitude": 21.0067249
		},
		"europe-west8": {
			"short_name": "europe-west8",
			"long_name": "Milan",
			"latitude": 45.4641943,
			"longitude": 9.1896346
		},
		"europe-southwest1": {
			"short_name": "europe-southwest1",
			"long_name": "Madrid",
			"latitude": 40.4167047,
			"longitude": -3.7035825
		},
		"europe-west9": {
			"short_name": "europe-west9",
			"long_name": "Paris",
			"latitude": 48.8588897,
			"longitude": 2.3200410217200766
		},
		"asia-south1": {
			"short_name": "asia-south1",
			"long_name": "Mumbai",
			"latitude": 19.0785451,
			"longitude": 72.878176
		},
		"asia-south2": {
			"short_name": "asia-south2",
			"long_name": "Delhi",
			"latitude": 28.6517178,
			"longitude": 77.2219388
		},
		"asia-southeast1": {
			"short_name": "asia-southeast1",
			"long_name": "Singapore",
			"latitude": 1.357107,
			"longitude": 103.8194992
		},
		"asia-southeast2": {
			"short_name": "asia-southeast2",
			"long_name": "Jakarta",
			"latitude": -6.1753942,
			"longitude": 106.827183
		},
		"asia-east2": {
			"short_name": "asia-east2",
			"long_name": "Hong Kong",
			"latitude": 22.2793278,
			"longitude": 114.1628131
		},
		"asia-east1": {
			"short_name": "asia-east1",
			"long_name": "Taiwan",
			"latitude": 23.9739374,
			"longitude": 120.9820179
		},
		"asia-northeast1": {
			"short_name": "asia-northeast1",
			"long_name": "Tokyo",
			"latitude": 35.6828387,
			"longitude": 139.7594549
		},
		"asia-northeast2": {
			"short_name": "asia-northeast2",
			"long_name": "Osaka",
			"latitude": 34.6198813,
			"longitude": 135.490357
		},
		"australia-southeast1": {
			"short_name": "australia-southeast1",
			"long_name": "Sydney",
			"latitude": -33.8698439,
			"longitude": 151.2082848
		},
		"australia-southeast2": {
			"short_name": "australia-southeast2",
			"long_name": "Melbourne",
			"latitude": -37.8142176,
			"longitude": 144.9631608
		},
		"asia-northeast3": {
			"short_name": "asia-northeast3",
			"long_name": "Seoul",
			"latitude": 37.5666791,
			"longitude": 126.9782914
		}
	},
	"aws": {
		"af-south-1": {
			"short_name": "af-south-1",
			"long_name": "Africa (Cape Town)",
			"latitude": -33.928992,
			"longitude": 18.417396
		},
		"ap-east-1": {
			"short_name": "ap-east-1",
			"long_name": "Asia Pacific (Hong Kong)",
			"latitude": 22.2793278,
			"longitude": 114.1628131
		},
		"ap-northeast-1": {
			"short_name": "ap-northeast-1",
			"long_name": "Asia Pacific (Tokyo)",
			"latitude": 35.6828387,
			"longitude": 139.7594549
		},
		"ap-northeast-2": {
			"short_name": "ap-northeast-2",
			"long_name": "Asia Pacific (Seoul)",
			"latitude": 37.5666791,
			"longitude": 126.9782914
		},
		"ap-northeast-3": {
			"short_name": "ap-northeast-3",
			"long_name": "Asia Pacific (Osaka)",
			"latitude": 34.6198813,
			"longitude": 135.490357
		},
		"ap-south-1": {
			"short_name": "ap-south-1",
			"long_name": "Asia Pacific (Mumbai)",
			"latitude": 19.0785451,
			"longitude": 72.878176
		},
		"ap-southeast-1": {
			"short_name": "ap-southeast-1",
			"long_name": "Asia Pacific (Singapore)",
			"latitude": 1.357107,
			"longitude": 103.8194992
		},
		"ap-southeast-2": {
			"short_name": "ap-southeast-2",
			"long_name": "Asia Pacific (Sydney)",
			"latitude": -33.8698439,
			"longitude": 151.2082848
		},
		"ap-southeast-3": {
			"short_name": "ap-southeast-3",
			"long_name": "Asia Pacific (Jakarta)",
			"latitude": -6.1753942,
			"longitude": 106.827183
		},
		"ca-central-1": {
			"short_name": "ca-central-1",
			"long_name": "Canada (Central)",
			"latitude": 45.5031824,
			"longitude": -73.5698065
		},
		"eu-central-1": {
			"short_name": "eu-central-1",
			"long_name": "Europe (Frankfurt)",
			"latitude": 50.1106444,
			"longitude": 8.6820917
		},
		"eu-north-1": {
			"short_name": "eu-north-1",
			"long_name": "Europe (Stockholm)",
			"latitude": 59.3251172,
			"longitude": 18.0710935
		},
		"eu-south-1": {
			"short_name": "eu-south-1",
			"long_name": "Europe (Milan)",
			"latitude": 45.4641943,
			"longitude": 9.1896346
		},
		"eu-west-1": {
			"short_name": "eu-west-1",
			"long_name": "Europe (Ireland)",
			"latitude": 53.3498006,
			"longitude": -6.2602964
		},
		"eu-west-2": {
			"short_name": "eu-west-2",
			"long_name": "Europe (London)",
			"latitude": 51.5073219,
			"longitude": -0.1276474
		},
		"eu-west-3": {
			"short_name": "eu-west-3",
			"long_name": "Europe (Paris)",
			"latitude": 48.8588897,
			"longitude": 2.3200410217200766
		},
		"me-central-1": {
			"short_name": "me-central-1",
			"long_name": "Middle East (UAE)",
			"latitude": 25.074282349999997,
			"longitude": 55.18853865430702
		},
		"me-south-1": {
			"short_name": "me-south-1",
			"long_name": "Middle East (Bahrain)",
			"latitude": 26.1551249,
			"longitude": 50.5344606
		},
		"sa-east-1": {
			"short_name": "sa-east-1",
			"long_name": "South America (Sao Paulo)",
			"latitude": -23.5506507,
			"longitude": -46.6333824
		},
		"us-east-1": {
			"short_name": "us-east-1",
			"long_name": "US East (N. Virginia)",
			"latitude": 39.030019100000004,
			"longitude": -77.46964646557657
		},
		"us-east-2": {
			"short_name": "us-east-2",
			"long_name": "US East (Ohio)",
			"latitude": 39.9622601,
			"longitude": -83.0007065
		},
		"us-west-1": {
			"short_name": "us-west-1",
			"long_name": "US West (N. California)",
			"latitude": 37.7790262,
			"longitude": -122.419906
		},
		"us-west-2": {
			"short_name": "us-west-2",
			"long_name": "US West (Oregon)",
			"latitude": 45.839855,
			"longitude": -119.7005834
		}
	},
	"example":{
			"US West": {
				"short_name": "us-west-2",
				"long_name": "US West (Oregon)",
				"latitude": 45.839855,
				"longitude": -119.7005834
			},
			"US East": {
				"short_name": "us-east-2",
				"long_name": "US West (Oregon)",
				"latitude": 39.9622601,
				"longitude": -83.0007065
			}
		}
}

var used_regions := {}

onready var world := $ViewportContainer/Viewport/WorldMesh
onready var camera_origin := $ViewportContainer/Viewport/CameraOrigin
onready var camera := $ViewportContainer/Viewport/CameraOrigin/Camera
onready var hint := $VBoxContainer/Hint
onready var sepparator := $VBoxContainer/HSeparator
onready var total_label := $VBoxContainer/Total
onready var hint_container := $VBoxContainer
onready var combo_box := $HBoxContainer/ComboBox


func _physics_process(delta):
	world.rotation.y += world_speed*delta
	
func _process(delta):
	camera.look_at(world.transform.origin, Vector3.UP)
	
	
func _input(event):
	if not get_global_rect().has_point(get_global_mouse_position()):
		mouse_pressed = false
		return
		
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		mouse_pressed = event.is_pressed()
		
	if event is InputEventMouseMotion and mouse_pressed:
		world.rotate(Vector3.UP, event.relative.x * 2 * PI / rect_size.x)
		var camera_rotation = clamp(camera_origin.rotation.z + event.relative.y * PI / rect_size.y, -PI/2+0.2, PI/2-0.2)
		camera_origin.rotation.z = camera_rotation
		combo_box.text = ""


func add_cyllinder(coordinates : Vector2, height := 1.0):
	var c := preload("res://components/dashboard/widget_world_map/world_map_column.tscn").instance()
	c.value = height
	c.coordinates = coordinates
	world.add_child(c)
	
	c.rotate(Vector3.FORWARD, PI/2)
	c.rotate(Vector3.UP, deg2rad(coordinates.y-90))
	c.rotate(Vector3.UP.cross(c.transform.basis.y), deg2rad(coordinates.x))
	
	c.translation -= c.transform.basis.y
	
	for cyllinder in world.get_children():
		if cyllinder == c:
			continue
			
		if cyllinder.coordinates == coordinates:
			c.translation -= c.transform.basis.y * cyllinder.value
		
	go_to_coordinate(coordinates)
	
	return c


func set_data(_data, _type : int):
	for column in world.get_children():
		column.queue_free()
		world.remove_child(column)
	
	if _type == DataSource.TYPES.AGGREGATE_SEARCH:
		var first_data : Dictionary = _data[0].duplicate()
		first_data.erase("group")
		var variable_name = first_data.keys()[0]
		
		# Look for max value to set column scales
		max_value = 0.0
		
		for data in _data:
			if data[variable_name] > max_value:
				max_value = data[variable_name]
				
		if max_value == 0.0:
			max_value = 1.0
			
		used_regions.clear()
				
		for data in _data:
			data = data as Dictionary
			if "region" in data["group"] and "cloud" in data["group"]:
				var cloud = data["group"]["cloud"]
				var region = data["group"]["region"]
				
				if not cloud in regions:
					return
				var coordinates = Vector2(regions[cloud][region]["latitude"], regions[cloud][region]["longitude"])
				
				used_regions["%s (%s)" % [region, cloud]] = coordinates
			
				var cyllinder = add_cyllinder(coordinates, data[variable_name] / max_value)
				cyllinder.cloud = cloud
				cyllinder.region = region
				
				cyllinder.connect("start_hovering", self, "_on_cyllinder_hovering_started", [coordinates, variable_name, cyllinder])
				cyllinder.connect("end_hovering", self, "_on_cyllinder_hovering_ended")
				cyllinder.connect("clicked", self, "go_to_coordinate")
				
		combo_box.items = used_regions.keys()


func _on_cyllinder_hovering_started(coordinates, variable_name, c):
	hint_container.show()
	var lines : PoolStringArray = []
	var total : float = 0.0
	for cyllinder in world.get_children():
		prints(cyllinder.coordinates == coordinates, cyllinder.coordinates, coordinates)
		if cyllinder.coordinates == coordinates:
			var value : float = cyllinder.value * max_value
			var line : String =  "%s %s in %s (%s)" % [str(value), variable_name, cyllinder.region, cyllinder.cloud]
			if c == cyllinder:
				line = "→ " + line
			lines.append(line)
			total += value
			
	
	hint.rect_min_size.y = 24 * lines.size()
	hint.text = lines.join("\n")
	
	if lines.size() > 1:
		total_label.show()
		sepparator.show()
		total_label.text = "Total %s: %s" % [variable_name, str(total)]
	else:
		total_label.hide()
		sepparator.hide()
		hint.text = hint.text.replace("→ ","")
		
	
	world_speed = 0.0


func _on_cyllinder_hovering_ended():
	hint_container.hide()
	world_speed = initial_world_speed


func go_to_coordinate(coordinates : Vector2, cloud := "", region := ""):
	if not "" in [cloud, region]:
		combo_box.text = "%s (%s)" % [region, cloud]
		
	var tween := create_tween()
	var target_rotation := Vector2(coordinates.x - 5, -coordinates.y - 90)
	if is_equal_approx(camera_origin.rotation_degrees.z, target_rotation.x) and is_equal_approx(world.rotation_degrees.y, target_rotation.y):
		return
		
	tween.tween_property(world, "rotation_degrees:y", target_rotation.y, 1).set_trans(Tween.TRANS_SINE)
	tween.parallel()
	tween.tween_property(camera_origin, "rotation_degrees:z", target_rotation.x, 1).set_trans(Tween.TRANS_SINE)
	
	var translation_tween := create_tween()
	translation_tween.tween_property(camera, "translation:x", 4.0, 0.5).set_trans(Tween.TRANS_SINE)
	translation_tween.tween_property(camera, "translation:x", 3.0, 0.5).set_trans(Tween.TRANS_SINE)


func _on_ComboBox_option_changed(option):
	if option in used_regions:
		go_to_coordinate(used_regions[option])
