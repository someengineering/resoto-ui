extends Node

signal navigate(destination_args)
signal navigation_index_changed(index)

var popstate_callback = JavaScript.create_callback(self, "_on_popstate_event")
var navigation_array := [{"view" : "home"}]
var navigation_index : int = 0 setget set_navigation_index
var current_navigation_state := {}

var can_navigate := true
var can_change_state := true

func _ready():
	if OS.has_feature("HTML5"):
		var window := JavaScript.get_interface("window")
		window.onpopstate = popstate_callback


func on_home_loaded():
	if OS.has_feature("HTML5"):
		var initial_hash := get_url_hash()
		if initial_hash != "":
			_on_popstate_event(initial_hash)


func get_url_hash() -> String:
	return JavaScript.eval("document.location.hash")


func _on_popstate_event(_args):
	if not can_navigate:
		return
		
	can_change_state = false
	var url_hash := get_url_hash()
	url_hash = url_hash.trim_prefix("#")

	var navigation_args = parse_navigation_args(url_hash)
	
	emit_signal("navigate", navigation_args)
	
	yield(get_tree().create_timer(0.1),"timeout")
	can_change_state = true


func set_current_navigation_state(args : Dictionary):
	if not can_change_state:
		return
		
	can_navigate = false
	
	if args.hash() == current_navigation_state.hash():
		return
		
	current_navigation_state = args
	
	if OS.has_feature("HTML5"):
		var view : String = args["view"]
		var args_array : PoolStringArray = []
		args.erase("view")
		for key in args:
			args_array.append("%s=%s" % [key, args[key]])
		
		if args_array.size() > 0:
			view += "?%s" % args_array.join("&")
			
		JavaScript.eval('document.location.hash = "%s"' % view)
	else:
		self.navigation_index += 1
		navigation_array.resize(navigation_index)
		navigation_array.append(args)
	can_navigate = true


func parse_navigation_args(string_args : String) -> Dictionary:
	var args : Dictionary = {}
	
	var view_array := string_args.split("?")
	args["view"] = view_array[0]
	
	if view_array.size() > 1:
		var args_array := view_array[1].split("&")
		
		for arg in args_array:
			var property = arg.split("=")
			args[property[0]] = property[1]
	
	return args


func back():
	if navigation_index > 0:
		self.navigation_index -= 1
		emit_signal("navigate", navigation_array[navigation_index])


func forward():
	if navigation_index < navigation_array.size() - 1:
		self.navigation_index += 1
		emit_signal("navigate", navigation_array[navigation_index])


func native_navigate(direction : String):
	if not can_navigate:
		return
		
	can_change_state = false
	
	call(direction)
	
	yield(get_tree().create_timer(0.1),"timeout")
	can_change_state = true


func set_navigation_index(new_index : int):
	navigation_index = new_index
	emit_signal("navigation_index_changed", navigation_index)
