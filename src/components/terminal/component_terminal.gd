extends VBoxContainer
class_name TerminalComponent

signal rename_terminal

const MODIFIER_KEYS:Array = [KEY_CONTROL, KEY_SHIFT, KEY_ALT, KEY_CAPSLOCK, KEY_META, KEY_MASK_META, KEY_MASK_CMD]
const UI_RENAME_COMMAND:String = "ui name "

var terminal_active: bool = false
var last_commands: Array  = []
var last_command_id: int  = 0
var active_request: ResotoAPI.Request
var just_grabbed_focus:bool = false

onready var console = find_node("RichResponseText")
onready var command = find_node("CommandEdit")
onready var console_v_scroll: VScrollBar = console.get_v_scroll()
onready var loading = find_node("Loading")


func _ready() -> void:
	loading.console = console
	console_v_scroll.connect("changed", self, "on_scroll_changed")
	var image = load("res://assets/Resoto-Logo_bigger.svg")
	
	for i in 5:
		console.newline()
	console.push_align(RichTextLabel.ALIGN_CENTER)
	console.add_image(image, 200, 200)
	console.newline()
	console.add_text("Resoto UI")
	for i in 5:
		console.newline()
	console.pop()


func _input(event:InputEvent) -> void:
	if not is_visible_in_tree() or !terminal_active or _g.popup_manager.popup_active() or not event is InputEventKey:
		return
	
	if !command.has_focus() and event.pressed and !MODIFIER_KEYS.has(event.scancode):
		just_grabbed_focus = true
		yield(get_tree(), "idle_frame")
		console.selection_enabled = false
		console.set_deferred("selection_enabled", true)
		command.grab_focus()
		Input.parse_input_event(event)
		return
	
	if (!just_grabbed_focus and command.has_focus() and event.scancode == KEY_C and event.pressed
	and (Input.is_key_pressed(KEY_META) or Input.is_key_pressed(KEY_CONTROL))):
		if command.text == "":
			new_line("^C")
		else:
			new_line(command.text, true)
			command.text = ""
		if active_request:
			active_request.abort()
		return
	
	just_grabbed_focus = false
	
	if command.has_focus() and (event.scancode == KEY_UP and event.pressed):
		command.text = last_commands[last_command_id]
		last_command_id = wrapi(last_command_id+1, 0, last_commands.size())
		command.set_deferred("caret_position", command.text.length())
	
	if command.has_focus() and (event.scancode == KEY_DOWN and event.pressed):
		command.text = last_commands[last_command_id]
		last_command_id = wrapi(last_command_id-1, 0, last_commands.size())
		command.set_deferred("caret_position", command.text.length())
	
	if command.has_focus() and (event.scancode == KEY_TAB and event.pressed):
		if "se" in command.text.left(5):
			command.text = "search "
		command.set_deferred("caret_position", command.text.length())


func _on_cli_execute_streamed_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		console.append_bbcode("\nError: [color=red]" + Utils.err_enum_to_string(error) + "[/color]")
		loading.stop()
	else:
		loading.stop()


func _on_cli_execute_streamed_data(data:String) -> void:
	if data.left(3) == "401":
		_g.popup_manager.open_popup("ConnectPopup")
	console.append_bbcode(str(data))


func on_scroll_changed() -> void:
	console_v_scroll.value = console_v_scroll.max_value


func _on_CommandEdit_text_entered(_new_command:String) -> void:
	if !terminal_active:
		return
	new_line(_new_command)
	console.append_bbcode("\n")
	if _new_command == "":
		return
	execute_command(_new_command)
	last_command_id = 0
	last_commands.push_front(_new_command)
	if last_commands.size() >= 1000:
		last_commands.resize(1000)
	command.text = ""


func execute_command(_command:String) -> void:
	if _command.left(8).to_lower() == UI_RENAME_COMMAND:
		var new_terminal_name = _command.split(UI_RENAME_COMMAND)[1]
		emit_signal("rename_terminal", new_terminal_name)
		return
	if !terminal_active:
		return
	active_request = API.cli_execute_streamed(_command, self)
	loading.start()


func new_line(_command:String = "", greyed:bool=false) -> void:
	var line_color:String = "[color=white]" if !greyed else "[color=gray]"
	console.append_bbcode("\n[b]"+ line_color +"> " + _command + "[/color][/b]")
