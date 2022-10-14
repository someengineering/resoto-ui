class_name ColorController
extends Node

export (String) var property : String = "background_color"
export (String) var control_variable : String = "value"
export (Array) var conditions : Array

onready var widget := get_parent()

func _process(delta):
	find_enclosing_conditions(property)

func find_enclosing_conditions(property : String):
	# condition must be [value, result_color]
	var value = widget.get(control_variable)
	
	var prev = -INF
	var next = INF
	
	var prev_result = null
	var next_result = null
	
	for condition in conditions:
		if condition[0] <= value and condition[0] > prev:
			prev = condition[0]
			prev_result = condition[1]
		elif condition[0] >= value and condition[0] < next:
			next = condition[0]
			next_result = condition[1]
			
	if prev == -INF and next == INF:
		# no condition for this property
		return
	
	var result : Color
	
	var ratio = 0
	if prev == -INF:
		ratio = 0
		result = next_result
	elif next == INF:
		ratio = 1
		result = prev_result
	elif prev == next:
		ratio = 1
		result = prev_result
	else:
		ratio = clamp((value - prev) / (next - prev), 0, 1)
		prev_result.a = 1.0-ratio
		result = next_result.blend(prev_result)
		
		
	widget.set(property, result)
	
	
	
