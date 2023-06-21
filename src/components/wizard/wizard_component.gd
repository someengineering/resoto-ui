extends MarginContainer

signal setup_wizard_finished
signal setup_wizard_collecting
signal setup_wizard_changed_config

var data:Dictionary

const DATA_FOLDER := "res://data/wizard_scripts/wizard_script_%s.json"

export var is_collector_config_wizard := false
export var wizard_script_name := ""
export var text_scroll_speed := 0.005

var visible_step_scene_names := ["StepText", "StepQuestion", "StepPrompt", "StepCustomScene", "StepMultipleFields"]

var wizard_step_scenes:Dictionary = {
	"StepSection" : preload("res://components/wizard/wizard_steps/wizard_step_section.tscn"),
	"StepText" : preload("res://components/wizard/wizard_steps/wizard_step_text.tscn"),
	"StepQuestion" : preload("res://components/wizard/wizard_steps/wizard_step_question.tscn"),
	"StepPrompt" : preload("res://components/wizard/wizard_steps/wizard_step_prompt.tscn"),
	"StepSectionGoto" : preload("res://components/wizard/wizard_steps/wizard_step_goto_section.tscn"),
	"StepUpdateConfig" : preload("res://components/wizard/wizard_steps/wizard_step_update_config.tscn"),
	"StepCreateObject" : preload("res://components/wizard/wizard_steps/wizard_step_create_object.tscn"),
	"StepHandleObject" : preload("res://components/wizard/wizard_steps/wizard_step_handle_object.tscn"),
	"StepSaveConfigsOnCore" : preload("res://components/wizard/wizard_steps/wizard_step_save_configs_on_core.tscn"),
	"StepSetVariable" : preload("res://components/wizard/wizard_steps/wizard_step_set_variable.tscn"),
	"StepConfigConditional" : preload("res://components/wizard/wizard_steps/wizard_step_config_conditional.tscn"),
	"StepVariableConditional" : preload("res://components/wizard/wizard_steps/wizard_step_variable_conditional.tscn"),
	"StepMultiPrompt" : preload("res://components/wizard/wizard_steps/wizard_step_multi_prompt.tscn"),
	"StepMultipleFields" : preload("res://components/wizard/wizard_steps/wizard_step_multiple_fields.tscn")
}

var current_step:Node = null
var last_step := ""
var help_link := ""
var new_json_objects := {}
var step_variables := {}
var home_section := ""
var home_section_id := ""
var remote_configs := {}
var remaining_configs_number := 0
var config_changed := false
var start_step_id := ""
var muted := false
var wizard_complete := false

onready var character = $BG/Character/WizardCharacter
onready var step_content = $BG/StepDisplay/StepContent
onready var next_button = $BG/StepDisplay/StepButtons/NextBtn
onready var prev_button = $BG/StepDisplay/StepButtons/PrevBtn
onready var help_url_button = $BG/StepDisplay/Titlebar/HelpURLButton
onready var help_hint_button = $BG/StepDisplay/Titlebar/HelpHintButton


func _ready():
	Style.add_self($BG, Style.c.BG)


func _input(event):
	if not is_visible_in_tree():
		return
	if event.is_action_released("ui_focus_next"):
		get_next_focus()
	elif event.is_action_pressed("ui_cancel"):
		lose_focus()
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and get_focus_owner() == null:
		_on_NextBtn_pressed()


func _process(_delta):
	if is_visible_in_tree() and get_focus_owner() == null:
		if next_button.visible and not next_button.disabled and next_button.get_focus_mode() == FOCUS_ALL:
			next_button.grab_focus()


func load_wizard_graph(_wizard_script_name:String=wizard_script_name):
	wizard_script_name = _wizard_script_name
	data = Utils.load_json_dict(DATA_FOLDER % wizard_script_name)
	if not (data.has("info") and data.has("nodes")):
		_g.emit_signal("add_toast", "No Wizard data found.", "", FAILED)
		return
	data["connections_from"] = {}
	data["connections_to"] = {}
	home_section = data.info.home_screen
	for c in data.connections:
		if not data.connections_from.has(c.from):
			data.connections_from[c.from] = []
		if not data.connections_to.has(c.to):
			data.connections_to[c.to] = []
		data.connections_from[c.from].append({"to":c.to, "from_port":c.from_port})
		data.connections_to[c.to].append({"from":c.from, "to_port":c.to_port})
	
	var used_configs:= {}
	for n in data.nodes.values():
		if n.has("config_key") and n.config_key != "":
			used_configs[n.config_key] = null
	
	remaining_configs_number = used_configs.size()
	get_remote_configs(used_configs.keys())


func get_remote_configs(_config_keys:Array):
	for _config_key in _config_keys:
		API.get_config_id(self, _config_key)


func _on_get_config_id_done(_error:int, _r:ResotoAPI.Response, _config_key:String):
	remaining_configs_number -= 1
	if _r.response_code >= 200 and _r.response_code < 300:
		remote_configs[_config_key] = _r.transformed.result	
	elif _r.response_code == 404:
		remote_configs[_config_key] = {}
	else:
		_g.emit_signal("add_toast", "Error receiving Config", "Config '%s' created a problem." % _config_key, FAILED)
	if remaining_configs_number <= 0:
		start_wizard()

func start_wizard():
	wizard_complete = false
	$BG/StepDisplay/Titlebar/HomeButton.hide()
	can_previous(true)
	for n_key in data.nodes:
		if data.nodes[n_key].has("section_name"):
			show_step(n_key)
			break


func set_custom_buttons(buttons : Array):
	next_button.visible = false
	prev_button.visible = false
	for button_data in buttons:
		var button := Button.new()
		button.text = button_data["text"]
		$BG/StepDisplay/StepButtons.add_child(button)
		button.connect("pressed", self, "show_step", [str(button_data["to"])])
		

func remove_custom_buttons():
	next_button.visible = true
	for button in $BG/StepDisplay/StepButtons.get_children():
		if button == prev_button or button == next_button:
			continue
		button.queue_free()


func show_step(_step_id:String):
	var step_data = get_step_data(_step_id)
		
	if start_step_id == "" and visible_step_scene_names.has(step_data.res_name):
		 start_step_id = _step_id
	
	prev_button.visible = start_step_id != _step_id
	can_previous(true)
	
	remove_custom_buttons()
	
	update_help(step_data)
	for c in step_content.get_children():
		if c.name == str(step_data.id):
			clear_step()
			current_step = c
			current_step.start(step_data)
			current_step.show()
#			$BG/StepDisplay/Titlebar/SectionTitleLabel.text = current_step.section_name
			
			next_button.text = "Close" if not data.connections_from.has(current_step.step_id) else "Next"
			check_if_can_finish_wizard(step_data)
			
			return
	
	if data.nodes.has(_step_id):
		clear_step()
		var new_step
		# check if it is a custom step...
		if step_data.res_name == "StepCustomScene":
			new_step = load(step_data.special_scene_path).instance()
		else:
			new_step = wizard_step_scenes[step_data.res_name].instance()
		
		new_step.wizard = self
		step_content.add_child(new_step)
		new_step.connect("next", self, "next_step")
		new_step.connect("can_continue", self, "can_continue")
		new_step.connect("can_previous", self, "can_previous")
		new_step.connect("update_section_title", self, "update_section_title")
		new_step.step_data = step_data
		new_step.name = str(step_data.id)
		new_step.step_id = str(step_data.id)
		new_step.section_name = $BG/StepDisplay/Titlebar/SectionTitleLabel.text
		new_step.last_step = last_step
		current_step = new_step
		next_button.text = "Close" if not data.connections_from.has(current_step.step_id) else "Next"
		check_if_can_finish_wizard(step_data)
		
		if step_data.res_name == "StepSection" and step_data.section_name == home_section:
			$BG/StepDisplay/Titlebar/HomeButton.show()
			home_section_id = str(step_data.id)
		
		current_step.start(step_data)
		


func check_if_can_finish_wizard(step_data:Dictionary):
	if not is_collector_config_wizard or not visible_step_scene_names.has(step_data.res_name):
		return
	# Show the Finish Setup button
	# This is very specific to the "Setup Wizard"
	
	if (step_data.has("uid")
	and step_data.uid == "configured_collectors"
	and config_changed):
		#finish_setup
		yield(VisualServer, "frame_post_draw")
		next_button.disabled = false
		next_button.set_meta("finish_setup", true)
		next_button.modulate = Color(0.8, 1.5, 0.8)
		next_button.text = "Finish Setup"
	else:
		yield(VisualServer, "frame_post_draw")
		next_button.remove_meta("finish_setup")
		next_button.modulate = Color.white
		next_button.text = "Close" if not data.connections_from.has(current_step.step_id) else "Next"


func update_help(_step_data:Dictionary):
	help_link = "" if not _step_data.has("docs_link") else _step_data.docs_link
	
	if help_link.begins_with("http"):
		help_url_button.visible = true
		help_hint_button.visible = false
		help_url_button.hint_tooltip = help_link
	elif help_link != "":
		help_url_button.visible = true
		help_hint_button.visible = false
		help_url_button.hint_tooltip = help_link
	else:
		help_url_button.visible = false
		help_hint_button.visible = false


func can_continue(_can: bool = true):
	next_button.disabled = !_can
	next_button.focus_mode = Control.FOCUS_ALL if _can else Control.FOCUS_NONE


func can_previous(_can:bool):
	if current_step and not current_step.custom_buttons.empty():
		set_custom_buttons(current_step.custom_buttons)
	else:
		prev_button.disabled = !_can
		next_button.focus_mode = Control.FOCUS_ALL if _can else Control.FOCUS_NONE
		$BG/StepDisplay/Titlebar/HomeButton.disabled = !_can
		$BG/StepDisplay/Titlebar/HomeButton.modulate.a = 0.1 if !_can else 1.0


func next_step(_next_on_slot:int=0):
	lose_focus()
	if not current_step.skip_for_history or last_step == "":
		last_step = str(current_step.step_id)
	
	next_button.disabled = true
	next_button.focus_mode = Control.FOCUS_NONE
	
	if data.connections_from.has(current_step.step_id):
		var connected:Array = data.connections_from[current_step.step_id]
		if connected.size() == 1:
			show_step(connected[0].to)
		elif connected.size() == 0:
			print("ERROR: No connection to next?")
		else:
			for c in connected:
				if c.from_port == _next_on_slot:
					show_step(c.to)


func get_next_focus():
	if current_step.has_method("get_answer_buttons"):
		var buttons:Array = current_step.get_answer_buttons()
		buttons[0].grab_focus()
	else:
		if not next_button.disabled:
			next_button.grab_focus()
		elif not prev_button.disabled:
			prev_button.grab_focus()


func lose_focus():
	if get_focus_owner():
		get_focus_owner().release_focus()


func clear_step():
	for c in step_content.get_children():
		if c is ReferenceRect:
			continue
		c.hide()


func prev_step():
	clear_step()
	show_step(current_step.last_step)


func update_section_title(_new_name:String):
	$BG/StepDisplay/Titlebar/SectionTitleLabel.text = _new_name


func get_step_data(_node_id:String) -> Dictionary:
	if data.nodes.has(_node_id):
		return data.nodes[_node_id]
	else:
		print("Error: Step %s not found!" % _node_id)
		return {}


func change_section(_step_id:String):
	for node in data.nodes.values():
		if node.has("section_name") and node.section_name == _step_id:
			show_step(str(node.id))


func _on_PrevBtn_pressed():
	if prev_button.disabled:
		return
	next_button.disabled = true
	next_button.focus_mode = Control.FOCUS_NONE
	prev_step()


func _on_NextBtn_pressed():
	if next_button.disabled:
		return
	if next_button.has_meta("finish_setup"):
		change_section("finish_setup")
		return
	
	if current_step.do_intercept_next:
		current_step.consume_next()
		return
	
	if not data.connections_from.has(current_step.step_id):
		wizard_complete = true
		emit_signal("setup_wizard_finished")
		return
	next_step()


func _on_HelpButton_pressed():
	OS.shell_open(help_link)


func _on_HomeButton_pressed():
	show_step(home_section_id)


func _on_HelpDiscordButton_pressed():
	OS.shell_open(_g.discord_link)


const sound_on_tex = preload("res://assets/icons/icon_128_sound_on.svg")
const sound_off_tex = preload("res://assets/icons/icon_128_sound_muted.svg")
func _on_MuteButton_pressed():
	muted = !muted
	$BG/StepDisplay/Titlebar/MuteButton.icon_tex = sound_off_tex if muted else sound_on_tex
	$BG/StepDisplay/Titlebar/MuteButton.hint_tooltip = "Mute Wizard Sound" if not muted else "Play Wizard Sound"
	character.mute(muted)
