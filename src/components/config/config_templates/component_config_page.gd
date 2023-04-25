extends VBoxContainer

var config_component:Node = null
var value setget ,get_value
var key:String = ""
var kind:String = ""
var kind_type:String = ""
var model:Dictionary
var content_elements:Array = []


func get_value():
	if not self.is_inside_tree():
		yield(self, "ready")
	
	var found_kind_type = "complex"
	if not model.empty():
		found_kind_type = config_component.get_kind_type(model.fqn)
	
	match found_kind_type:
		"simple":
			return config_component.build_simple(content_elements)
		"array":
			var new_value:Array = config_component.build_array(content_elements)
			return new_value
		"dict":
			var new_value:Dictionary = config_component.build_simple(content_elements)
			return new_value
		"complex":
			var new_value:Dictionary = config_component.build_dict(content_elements)
			return new_value
