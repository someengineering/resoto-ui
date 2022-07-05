extends Node

var shortcut_list:Dictionary = {
	"copy"		: KEY_C,
	"paste"		: KEY_V,
	"cut"		: KEY_X,
	"undo"		: KEY_Z,
	"redo"		: KEY_Z,
	"del_line"	: KEY_K,
	"select_all": KEY_A,
	"move_r"	: KEY_F,
	"move_l"	: KEY_B,
	"move_u"	: KEY_P,
	"move_d"	: KEY_N,
	"del"		: KEY_D,
	"bspc"		: KEY_H,
	"home"		: KEY_LEFT,
	"end"		: KEY_RIGHT,
}

var _clipboard_callback:JavaScriptObject	= JavaScript.create_callback(self, "_on_clipboard")
var copied:bool								= false
var os										= "Windows"

var is_web									= OS.has_feature("HTML5")
onready var navigator:JavaScriptObject		= JavaScript.get_interface("navigator")


func _ready():
	if not is_web:
		return
	os = JavaScript.eval("getOS()")
	if os == "MacOS":
		add_mac_actions()


func add_mac_actions():
	for key in shortcut_list.keys():
		var new_event = InputEventKey.new()
		new_event.scancode = shortcut_list[key]
		new_event.meta = true
		new_event.pressed = true
		if key == "redo":
			new_event.shift = true
		InputMap.add_action("mac_" + key)
		InputMap.action_add_event("mac_" + key, new_event)


func _input(event):
	if not is_web:
		return
	if event is InputEventKey and event.pressed:
		if os != "MacOS":
			# Handling default Inputs (Windows)
			if event.scancode == KEY_V and not copied:
				copied = true
				var obj = navigator.clipboard.readText().then(_clipboard_callback)
				get_tree().set_input_as_handled()
		else:
			# Handling Mac Input
			if event.is_action_pressed("mac_copy"):
				simulate_input(KEY_C)
			if event.is_action_pressed("mac_paste") and not copied:
				copied = true
				var obj = navigator.clipboard.readText().then(_clipboard_callback)
			if event.is_action_pressed("mac_cut"):
				simulate_input(KEY_X)
			if event.is_action_pressed("mac_select_all"):
				simulate_input(KEY_A)


func _on_clipboard(args):
	OS.clipboard = args[0]
	simulate_input(KEY_V)
	copied = false


func simulate_input(new_scancode):
	var input_event = InputEventKey.new()
	input_event.scancode = new_scancode
	input_event.control = true
	input_event.pressed = true
	Input.parse_input_event(input_event)
	
	input_event.pressed = false
	Input.parse_input_event(input_event)
