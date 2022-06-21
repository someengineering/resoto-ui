tool
class_name MeanIndicator
extends Control

export (float) var value : float setget set_value
export (String) var variable_name := "" setget set_variable_name
export (String) var unit := "" setget set_unit

var decimal_digits := 2 setget set_decimal_digits
var color := Color.white setget set_color
var background_color := Color("#282828") setget set_background_color

onready var name_label := $IndicatorBackground/VariableName
onready var value_label := $IndicatorBackground/ValueLabel
onready var unit_label := $IndicatorBackground/UnitLabel
onready var color_rect := $IndicatorBackground
onready var value_font : DynamicFont = value_label.get("custom_fonts/font")
onready var variable_font : DynamicFont = name_label.get("custom_fonts/font")
onready var unit_font : DynamicFont = unit_label.get("custom_fonts/font")

func _ready():
	set_variable_name(variable_name)
	set_unit(unit)
	set_background_color(background_color)
	set_decimal_digits(decimal_digits)
	set_color(color)

func get_settings() -> Dictionary:
	var data := {
		"background_color" : background_color.to_html(),
		"variable_name" : variable_name,
		"unit" : unit
	}
	return data
	
func set_settings(data : Dictionary):
	for key in data:
		if key == "background_color":
			self.background_color = Color(data[key])
		else:
			set(key, data[key])
	
func set_variable_name(new_name : String):
	variable_name = new_name
	if is_instance_valid(name_label):
		name_label.text = new_name
		name_label._on_DynamicLabel_resized()
	
func set_unit(new_unit : String):
	unit = new_unit
	if is_instance_valid(unit_label):
		unit_label.text = new_unit
		unit_label._on_DynamicLabel_resized()
	
func set_background_color(new_color):
	if new_color is String:
		new_color = str2var(new_color)
	background_color = new_color
	if is_instance_valid(color_rect):
		color_rect.color = new_color

func set_value(new_value):
	value = float(new_value)
	if is_instance_valid(value_label):
		if new_value is String and not new_value.is_valid_float():
			value_label.text = new_value
			value_label._on_DynamicLabel_resized()
		else:
			var format := "%."+str(decimal_digits)+"f"
			value_label.text = format % stepify(value, 1.0/pow(10, decimal_digits))
			value_label._on_DynamicLabel_resized()

func set_decimal_digits(d:int):
	decimal_digits = d
	set_value(value)
	
func set_color(new_color : Color):
	color = new_color
	if is_instance_valid(value_label):
		value_label.set("custom_colors/font_color", new_color)
	
func _get_property_list():
	var properties = []
	properties.append({
		name = "Widget Settings",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})

	properties.append({
		"name" : "decimal_digits",
		"type" : TYPE_INT
	})
	
	properties.append({
		"name" : "unit",
		"type" : TYPE_STRING
	})
	
	properties.append({
		"name" : "background_color",
		"type" : TYPE_COLOR
	})
	
	return properties
