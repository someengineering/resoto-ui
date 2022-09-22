extends Control
class_name TerminalComponent

signal rename_terminal

const MODIFIER_KEYS:Array = [KEY_CONTROL, KEY_SHIFT, KEY_ALT, KEY_CAPSLOCK, KEY_META, KEY_MASK_META, KEY_MASK_CMD]

var terminal_active: bool = false
var last_command_id: int  = -1
var current_command:String = ""
var active_request: ResotoAPI.Request
var just_grabbed_focus:bool = false

var cmd_rename:UITerminalCommand = UITerminalCommand.new("name ", "terminal_cmd_rename")
var terminal_commands:Array = [cmd_rename]

onready var console = find_node("RichResponseText")
onready var command = find_node("CommandEdit")
onready var console_v_scroll: VScrollBar = console.get_v_scroll()
onready var loading = find_node("Loading")


class UITerminalCommand:
	var command_name:String
	var command_function_name:String
	
	func _init(_cn:String, _cfn:String):
		command_name = _cn
		command_function_name = _cfn
	
	func exec(_parent:Node, _params:Array):
		if _parent.has_method(command_function_name):
			_parent.call(command_function_name, _params)
		

func _ready() -> void:
	if not _g.is_connected_to_resotocore:
		yield(_g, "connected_to_resotocore")
	
	loading.console = console
	console_v_scroll.connect("changed", self, "on_scroll_changed")
	var image = load("res://assets/Resoto-Logo_bigger.svg")
	
	for i in 5:
		console.newline()
	console.push_align(RichTextLabel.ALIGN_CENTER)
	console.add_image(image, 200, 200)
	console.newline()
	console.append_bbcode("[b]Resoto[/b]\nVersion: " + _g.resotocore_version)
	for i in 5:
		console.newline()
	console.pop()


func _input(event:InputEvent) -> void:
	if (not is_visible_in_tree()
	or !terminal_active
	or _g.popup_manager.popup_active()
	or not event is InputEventKey
	or _g.focus_in_search):
		return
	
	if not command.has_focus() and event.pressed and not MODIFIER_KEYS.has(event.scancode):
		just_grabbed_focus = true
		yield(get_tree(), "idle_frame")
		console.selection_enabled = false
		console.set_deferred("selection_enabled", true)
		command.grab_focus()
		Input.parse_input_event(event)
		return
	
	if (not just_grabbed_focus and command.has_focus() and event.scancode == KEY_C and event.pressed
	and (Input.is_key_pressed(KEY_META) or Input.is_key_pressed(KEY_CONTROL))):
		if command.get_selection_text() != "":
			yield(get_tree(), "idle_frame")
			command.deselect()
			return
		
		if command.text == "":
			new_line("^C", true)
		else:
			var cursor_pos = command.cursor_get_column()
			var cancel_text:String = command.text
			cancel_text.erase(cursor_pos, 2)
			cancel_text = cancel_text.insert(cursor_pos, "^C")
			new_line(cancel_text, true)
			command.text = ""
		if active_request:
			active_request.abort()
		return
	
	just_grabbed_focus = false
	
	if (event is InputEventKey and event.shift):
		return
	
	if command.has_focus() and ((event.scancode == KEY_UP or event.scancode == KEY_DOWN) and event.pressed):
		if last_command_id == -1:
			current_command = command.text
		
		var change_id = 1 if event.scancode == KEY_UP else -1
		last_command_id = clamp(last_command_id+change_id, -2, _g.terminal_scrollback.size()-1)
		
		if current_command == "" and last_command_id == -2:
			last_command_id = -1
		
		if last_command_id >= 0:
			command.text = _g.terminal_scrollback[last_command_id]
		elif last_command_id == -1:
			command.text = current_command
		elif last_command_id == -2:
			command.text = ""
		
		command.call_deferred("cursor_set_column", command.text.length())


func _on_cli_execute_streamed_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		console.append_bbcode("\nError: [color=red]" + Utils.err_enum_to_string(error) + "[/color]")
		loading.stop()
	else:
		if console.text.ends_with("\n"):
			console.text.trim_suffix("\n")
		loading.stop()


func _on_cli_execute_streamed_data(data:String) -> void:
	if data.left(3) == "401":
		_g.popup_manager.open_popup("ConnectPopup")
	console.append_bbcode(str(data))


func on_scroll_changed() -> void:
	console_v_scroll.value = console_v_scroll.max_value


func _on_CommandEdit_text_entered() -> void:
	if !terminal_active:
		return
	var _new_command = command.text
	new_line(_new_command)
	if _new_command == "":
		return
	execute_command(_new_command)
	last_command_id = -1
	current_command = ""
	_g.terminal_scrollback.push_front(_new_command)
	# Add the last commands to the UI config!
	if _g.terminal_scrollback.size() >= 256:
		_g.terminal_scrollback.resize(256)
	SaveLoadSettings.save_settings()
	command.text = ""


func execute_command(_command:String) -> void:
	if _command.left(3).to_lower() == "ui ":
		_command = _command.trim_prefix("ui ")
		for cmd in terminal_commands:
			if _command.begins_with(cmd.command_name):
				var new_terminal_name = _command.trim_prefix(cmd.command_name)
				cmd.exec(self, [new_terminal_name])
				return
		console.add_text("Error: UI command is not known.")
		return
	if !terminal_active:
		return
	console.add_text("\n")
	active_request = API.cli_execute_streamed(_command, self)
	loading.start()


func terminal_cmd_rename(_params:Array):
	emit_signal("rename_terminal", _params[0])


func new_line(_command:String = "", greyed:bool=false) -> void:
	var line_color:String = "[color=white]" if !greyed else "[color=gray]"
	console.append_bbcode("\n[b]"+ line_color +"> " + _command + "[/color][/b]")


func _on_CommandEdit_gui_input(event):
	if not event is InputEventKey:
		return
	if event.pressed and event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER:
		command.text = command.text.replace("\n", "")
		_on_CommandEdit_text_entered()
