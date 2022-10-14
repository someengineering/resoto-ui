class_name BaseWidget
extends Control

enum DATA_TYPE {INSTANT, RANGE}

export (DATA_TYPE) var data_type = DATA_TYPE.INSTANT

# This must be defined in DashboardContainer.WidgetScenes
export var widget_type_id:String = "Not Defined"

# 0 max_data_sources means infinite
export (int) var max_data_sources : int = 1
export (bool) var single_value : bool = false
export (Array, DataSource.TYPES) var supported_types

var color_controllers_data : Array setget set_color_controllers_data

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

func set_data(data, type : int):
	pass

