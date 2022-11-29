extends Control
class_name TerminalComponent

signal rename_terminal

const MODIFIER_KEYS:Array = [KEY_CONTROL, KEY_SHIFT, KEY_ALT, KEY_CAPSLOCK, KEY_META, KEY_MASK_META, KEY_MASK_CMD]

var terminal_active: bool = false setget set_terminal_active
var last_command_id: int  = -1
var current_command:String = ""
var active_request: ResotoAPI.Request
var just_grabbed_focus:bool = false
var connected:bool = false

var cmd_rename:UITerminalCommand = UITerminalCommand.new("name ", "terminal_cmd_rename")
var terminal_commands:Array = [cmd_rename]

var data_chunks:PoolStringArray = []
var chunk_idx:int = 0
var line_count:int = 0
var max_data_chunks:int = 1000
var write_line_count:int = 1000

var esc_pressed := false

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
	loading.console = console
	if not _g.is_connected_to_resotocore:
		yield(_g, "connected_to_resotocore")
	connected = true
	console_v_scroll.connect("changed", self, "on_scroll_changed")
	var image = load("res://assets/resoto/Resoto-Logo_bigger.svg")
	
	for i in 5:
		console.newline()
	console.push_align(RichTextLabel.ALIGN_CENTER)
	console.add_image(image, 200, 200)
	console.newline()
	console.append_bbcode("[b]Resoto Shell Lite[/b]\nResoto Core Version: " + _g.resotocore_version)
	console.append_bbcode("\n[i]We recommend using the full Resoto Shell for a better CLI experience.[/i]")
	console.append_bbcode("\n[url=url::https://resoto.com/docs/concepts/components/shell]Learn more about the Resoto Shell[img=8x8]res://assets/icons/icon_128_external_link_colored.svg[/img][/url]")
	for i in 5:
		console.newline()
	console.pop()

	data_chunks.resize(max_data_chunks)
	

func _input(event:InputEvent) -> void:
	if (not is_visible_in_tree()
	or !terminal_active
	or _g.popup_manager.popup_active()
	or not event is InputEventKey
	or _g.focus_in_search):
		return
	
	if not command.has_focus() and event.pressed and not MODIFIER_KEYS.has(event.scancode) and event.scancode != KEY_ESCAPE:
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
	
	elif event is InputEventWithModifiers and event.is_pressed():
		if event.control:
			var handled := true
			match event.scancode:
				KEY_A:
					command.selecting_enabled = false
					command.call_deferred("cursor_set_column", 0)
					command.set_deferred("selecting_enabled", true)
				KEY_E:
					command.call_deferred("cursor_set_column", command.text.length())
				KEY_U:
					var current_text : String = command.text
					current_text.erase(0, command.cursor_get_column())
					command.text = current_text
				KEY_L:
					console.text = ""
				KEY_K:
					var current_text : String = command.text
					current_text.erase(command.cursor_get_column(), current_text.length())
					command.text = current_text
					command.call_deferred("cursor_set_column", command.text.length())
				KEY_H:
					var c : int = command.cursor_get_column()
					var current_text : String = command.text
					current_text.erase(c-1, 1)
					command.text = current_text
					command.cursor_set_column(c-1)
				KEY_D:
					var c : int = command.cursor_get_column()
					var current_text : String = command.text
					current_text.erase(c, 1)
					command.text = current_text
					command.cursor_set_column(c)
				KEY_B:
					command.cursor_set_column(command.cursor_get_column() - 1)
				KEY_F:
					command.cursor_set_column(command.cursor_get_column() + 1)
				_:
					handled = false
					
			if handled:
				get_tree().set_input_as_handled()
			
		elif event.alt:
			var handled := true
			match event.scancode:
				KEY_LEFT:
					command.cursor_set_column(command.text.left(command.cursor_get_column() - 1).find_last(" ") + 1)
				KEY_RIGHT:
					command.cursor_set_column(command.text.find(" ", command.cursor_get_column() + 1) + 1)
				_:
					handled = false
			
			if handled:
				get_tree().set_input_as_handled()
		
	
	if event.scancode == KEY_ESCAPE:
		if event.is_pressed() and command.has_focus() and not esc_pressed:
			esc_pressed = true
			get_tree().set_input_as_handled()
		else:
			esc_pressed = false
	
	if esc_pressed and event.is_pressed():
		match event.scancode:
			KEY_BACKSPACE:
				var text : String = command.text
				var c : int = command.cursor_get_column()
				var start : int = command.text.left(c - 1).find_last(" ")
				text.erase(start + 1, c - start - 2)
				command.text = text
				command.cursor_set_column(start + 2)
			KEY_D:
				command.readonly = true
				var text : String = command.text
				var c : int = command.cursor_get_column()
				var end : int = text.find(" ", c + 1)
				if end < 0:
					end = text.length()
				text.erase(c, end - c)
				command.text = text
				command.cursor_set_column(c)
				command.set_deferred("readonly", false)
	
	just_grabbed_focus = false
	
	if (event is InputEventKey and event.shift):
		return
	
	var up : bool = event.scancode == KEY_UP or (event is InputEventWithModifiers and event.control and event.scancode == KEY_P)
	var down : bool = event.scancode == KEY_DOWN or (event is InputEventWithModifiers and event.control and event.scancode == KEY_N)
	if command.has_focus() and ((up or down) and event.pressed):
		if last_command_id == -1:
			current_command = command.text
		
		var change_id = 1 if up else -1
		last_command_id = int(clamp(last_command_id+change_id, -2, _g.terminal_scrollback.size()-1))
		
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
		data_chunks.resize(chunk_idx)
		console.append_bbcode(data_chunks.join(""))
		data_chunks.resize(max_data_chunks)
		if console.text.ends_with("\n"):
			console.text.trim_suffix("\n")
		loading.stop()
		
	data_chunks = []
	data_chunks.resize(max_data_chunks)


func _on_cli_execute_streamed_data(data:String) -> void:
	if data.left(3) == "401":
		_g.popup_manager.open_popup("ConnectPopup")
		return
	
	data_chunks[chunk_idx] = data
	chunk_idx += 1
	line_count += data.count("\n")
	
	if line_count > write_line_count:
		data_chunks.resize(chunk_idx)
		console.append_bbcode(data_chunks)
		data_chunks.resize(max_data_chunks)
		chunk_idx = 0
		line_count = 0
		
	elif chunk_idx == max_data_chunks:
		console.append_bbcode(data_chunks.join(""))
		chunk_idx = 0
		line_count = 0


func set_terminal_active(_terminal_active:bool) -> void:
	terminal_active = _terminal_active
	command.grab_focus()


func on_scroll_changed() -> void:
	console_v_scroll.value = console_v_scroll.max_value


func _on_CommandEdit_text_entered() -> void:
	if not terminal_active:
		return
	var _new_command = command.text
	new_line(_new_command)
	if _new_command == "":
		return
	if not connected:
		console.append_bbcode("\n[b][color=red]> Not connected to Resoto Core or not authorized.[/color][/b]")
		current_command = ""
		command.text = ""
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


func _on_RichResponseText_meta_clicked(meta:String):
	if meta.begins_with("url::"):
		OS.shell_open(meta.trim_prefix("url::"))


func _on_RichResponseText_gui_input(event:InputEventMouseButton):
	if event is InputEventMouseButton and not event.is_pressed() and console.get_selected_text() == "":
		command.grab_focus()
