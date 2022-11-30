class_name BaseWidget
extends Control

signal available_properties_changed

enum DATA_TYPE {INSTANT, RANGE}

const UnitsBytes := ["B", "KB", "MB", "GB", "TB", "PB"]

export (DATA_TYPE) var data_type = DATA_TYPE.INSTANT

# This must be defined in DashboardContainer.WidgetScenes
export var widget_type_id:String = "Not Defined"

# 0 max_data_sources means infinite
export (int) var max_data_sources : int = 1
export (bool) var single_value : bool = false
export (Array, DataSource.TYPES) var supported_types
export (Array, String) var attributes_to_save := []

var color_controllers_data : Array setget set_color_controllers_data
var is_preview_widget : bool = false

func set_color_controllers_data(data : Array):
	color_controllers_data = data
	var controllers := []
	
	for child in get_children():
		if child is ColorController:
			controllers.append(child)
			
	if controllers.size() != data.size():
		_g.emit_signal("add_toast","Wrong number of Color controllers", "Widget and saved color controllers number are different.", 1, self)
		return
	
	for i in controllers.size():
		var conditions = str2var(data[i])
		controllers[i].conditions = conditions

func set_data(_data, _type : int):
	pass

func get_attributes_to_save() -> Array:
	var attributes := []
	
	for attribute in attributes_to_save:
		attributes.append({
			attribute : get(attribute)
		})
	return attributes
	
func get_scaled_value(_value : float, factor : float = 1024.0) -> Dictionary:
	var new_value = _value
	var power : int = 0
	while true:
		new_value /= factor
		if new_value < 1 or power == 4:
			break
		power += 1
		_value = new_value
	
	return {"value" : _value, "unit": UnitsBytes[power]}
