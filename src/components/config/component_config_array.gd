extends VBoxContainer

var value:Array = [] setget set_value, get_value
var array_elements:Array = []
var kind:String = ""
var title:String = ""
var title_node:Control = null

onready var content = $Content
onready var Element = $ArrayElement

func set_value(_value:Array):
	value = _value
	refresh_elements()


func get_value():
	for i in array_elements.size():
		var element = array_elements[i]
		if element is LineEditInt:
			value[i] = int(element.text) if element.text != "" else null
		else:
			value[i] = element.text if element.text != "" else null
	return value


func refresh_elements():
	array_elements.clear()
	for c in content.get_children():
		if c.get_node("DeleteButton").is_connected("pressed", self, "_on_DeleteButton_pressed"):
			c.get_node("DeleteButton").disconnect("pressed", self, "_on_DeleteButton_pressed")
		c.queue_free()
	
	var array_pos:int = 0
	for v in value:
		var new_element = Element.duplicate()
		new_element.show()
		new_element.get_node("DeleteButton").connect("pressed", self, "_on_DeleteButton_pressed", [array_pos])
		var value_field:Node = null
		if kind == "string":
			value_field = new_element.get_node("VarValueString")
			value_field.text = str(v)
		elif kind == "int64":
			value_field = new_element.get_node("VarValueInt")
			value_field.value = int(v)
		array_elements.append(value_field)
		content.add_child(new_element)
		array_pos += 1
	
	title_node.text = title + " [" + str(value.size()) + "]"


func _on_AddButton_pressed():
	value = get_value()
	if kind == "string":
		value.append("")
	elif kind == "int64":
		value.append(0)
	refresh_elements()


func _on_DeleteButton_pressed(_array_pos:int):
	value.remove(_array_pos)
	refresh_elements()
