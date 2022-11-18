extends Node

var emulations : Array						= []
var _clipboard_callback:JavaScriptObject	= JavaScript.create_callback(self, "_on_clipboard")
var refreshing_clipboard:bool				= false

var is_web:bool								= OS.has_feature("HTML5")
var godot_watchdog_timer:float				= 0.0

onready var navigator:JavaScriptObject		= JavaScript.get_interface("navigator")


class KeyEmulation:
	var action: String = ""
	var key: int = -1
	var meta: bool = false
	var alt: bool = false
	var shift: bool = false
	
	func _init(_a:String, _k:int, _m:bool, _alt:bool=false, _s:bool=false):
		action = _a
		key = _k
		meta = _m
		alt = _alt
		shift = _s


func _ready():
	if not is_web:
		set_physics_process(false)
		return
	
	_g.os = JavaScript.eval("getOS()")
	if _g.os == "MacOS" and not InputMap.has_action("mac_copy"):
		add_mac_actions()
	
	JavaScript.eval("godotWatchdogStart()")


func _physics_process(delta:float):
	godot_watchdog_timer += delta
	if godot_watchdog_timer >= 1.0:
		godot_watchdog_timer -= 1.0
		JavaScript.eval("godotWatchdogNotification()")


func add_mac_actions():
	emulations.append(KeyEmulation.new("mac_copy", KEY_C, true))
	emulations.append(KeyEmulation.new("mac_paste", KEY_V, true))
	emulations.append(KeyEmulation.new("mac_cut", KEY_X, true))
	emulations.append(KeyEmulation.new("mac_select_all", KEY_A, true))
	emulations.append(KeyEmulation.new("mac_save", KEY_S, true))
	emulations.append(KeyEmulation.new("mac_search", KEY_F, true))
	emulations.append(KeyEmulation.new("mac_undo", KEY_Z, true))
	emulations.append(KeyEmulation.new("mac_redo", KEY_Z, true, false, true))
	emulations.append(KeyEmulation.new("mac_k", KEY_K, false, true, false))
	
	for key_emulation in emulations:
		var new_event : InputEventKey = InputEventKey.new()
		key_emulation = (key_emulation as KeyEmulation)
		new_event.scancode = key_emulation.key
		new_event.meta = key_emulation.meta
		new_event.shift = key_emulation.shift
		new_event.pressed = true
		InputMap.add_action(key_emulation.action)
		InputMap.action_add_event(key_emulation.action, new_event)


func _input(event):
	if not is_web:
		return
	if event is InputEventKey and event.is_pressed() and (event.control or event.alt or event.shift or event.meta):
		if _g.os != "MacOS":
			# Handling default Inputs (Windows)
			if event.scancode == KEY_V and not refreshing_clipboard:
				refreshing_clipboard = true
				var _obj : Object = navigator.clipboard.readText().then(_clipboard_callback)
				get_tree().set_input_as_handled()
		else:
			# Handling Mac Input
			for action in emulations:
				if event.is_action_pressed("mac_paste"):
					if not refreshing_clipboard:
						refreshing_clipboard = true
						var _obj : Object = navigator.clipboard.readText().then(_clipboard_callback)
						get_tree().set_input_as_handled()
				elif event.is_action_pressed(action.action):
					simulate_input(action.key, action.shift)
					get_tree().set_input_as_handled()


func _on_clipboard(args):
	if args.empty():
		args.append("")
	OS.clipboard = args[0]
	simulate_input(KEY_V)
	yield(get_tree(), "idle_frame")
	refreshing_clipboard = false


func simulate_input(scancode:int, shift:bool=false):
	var input_event : InputEventKey = InputEventKey.new()
	input_event.scancode = scancode
	input_event.control = true
	input_event.shift = shift
	input_event.pressed = true
	Input.parse_input_event(input_event)
	yield(get_tree(), "idle_frame")
	input_event.pressed = false
	Input.parse_input_event(input_event)
