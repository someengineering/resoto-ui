extends Control

const file_path:= "res://data/wizard_scripts/"
const file_name:= "wizard_script_%s.json"

var wizard_graph_node_scenes:Dictionary = {
	"StepSection" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_section.tscn"),
	"StepText" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_text.tscn"),
	"StepQuestion" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_question.tscn"),
	"StepAnswer" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_answer.tscn"),
	"StepSectionGoto" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_goto_section.tscn"),
	"StepPrompt" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_prompt.tscn"),
	"StepUpdateConfig" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_change_value.tscn"),
	"StepCreateObject" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_create_object.tscn"),
	"StepHandleObject" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_handle_object.tscn"),
	"StepComment" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_comment.tscn"),
	"StepSetVariable" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_set_variable.tscn"),
	"StepSaveConfigsOnCore" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_save_configs_on_core.tscn"),
	"StepCustomScene" : preload("res://components/wizard_editor/wizard_editor_nodes/wizard_editor_node_custom_scene.tscn")
}

var initial_position:= Vector2(60,60)
var opened_popup_pos:= Vector2.ZERO
var use_popup_pos:= false
var from_graph_node:GraphNode = null
var current_homescreen:= ""

var nodes:Array = []

var data:Dictionary = {}

onready var graph_edit = $VBox/GraphEdit
onready var add_popup = $PopupPanel
onready var script_edit = $VBox/PanelContainer/Toolbar/ScriptEdit
onready var homescreen_edit = $VBox/PanelContainer/Toolbar/HomeScreenEdit


static func load_json(path:String) -> Dictionary:
	var file = File.new()
	if !file.file_exists(path):
		return {}
	file.open(path, file.READ)
	var tmp_text = file.get_as_text()
	file.close()
	var _data = parse_json(tmp_text)
	return _data


static func save_json(path:String, file_name:String, _data):
	var directory = Directory.new()
	if not directory.dir_exists(path):
		var error = directory.make_dir(path)
		if error:
			print("Error creating directory")
	
	var file = File.new()
	file.open(path+file_name, file.WRITE)
	file.store_string(to_json(_data))
	file.close()


func _ready():
	UINavigation.change_title("Wizard Editor")
	var start_section = add_step("StepSection")
	start_section.section_name = "start"
	current_homescreen = "start"
	start_section.get_node("TextEdit").text = "start"
	update_homescreen_list()
	$VBox/PanelContainer/Toolbar/ScriptEdit.text = "default"

func _on_AddSectionStart_pressed():
	add_step("StepSection")

func _on_AddTextButton_pressed():
	add_step("StepText")

func _on_AddQuestionButton_pressed():
	add_step("StepQuestion")

func _on_AddAnswerButton_pressed():
	add_step("StepAnswer")

func _on_AddPromptButton_pressed():
	add_step("StepPrompt")

func _on_AddGoToSection_pressed():
	add_step("StepSectionGoto")

func _on_AddUpdateConfigButton_pressed():
	add_step("StepUpdateConfig")

func _on_AddCreateObjectButton_pressed():
	add_step("StepCreateObject")

func _on_AddSendObjectButton_pressed():
	add_step("StepHandleObject")

func _on_SaveConfigsButton_pressed():
	add_step("StepSaveConfigsOnCore")

func _on_SetVarButton_pressed():
	add_step("StepSetVariable")

func _on_AddComment_pressed():
	from_graph_node = null
	add_step("StepComment")

func _on_CustomSceneButton_pressed():
	add_step("StepCustomScene")


func add_step(scene_name:String, _new_id:int = -1):
	var new_step = wizard_graph_node_scenes[scene_name].instance()
	graph_edit.add_child(new_step)
	if _new_id == -1:
		var new_id = new_step.get_instance_id()
		# check for double id in array!
		var id_free:= false
		while not id_free:
			for n in nodes:
				if n.step_id == new_id:
					new_id += 1
					break
			id_free = true
		
		new_step.step_id = new_id
	else:
		new_step.step_id = _new_id
	new_step.name = str(new_step.step_id)
	
	if use_popup_pos:
		new_step.offset = (opened_popup_pos + Vector2(-4, -30)).snapped(Vector2(10,10))
		if from_graph_node != null:
			_on_GraphEdit_connection_request(from_graph_node.name, 0, new_step.name, 0)
	else:
		new_step.offset += initial_position + Vector2(rand_range(-80, 80),rand_range(-80, 80)).snapped(Vector2(10, 10)) + graph_edit.scroll_offset
	add_popup.hide()
	
	new_step.res_name = scene_name
	new_step.connect("close_request", self, "_on_GraphNode_close_request", [new_step])
	
	nodes.append(new_step)
	if scene_name == "StepSection":
		update_homescreen_list()
	
	return new_step


func _on_GraphNode_close_request(node:GraphNode) -> void:
	nodes.erase(node)
	node.queue_free()


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	graph_edit.connect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_connection_to_empty(from, from_slot:int, release_position:Vector2):
	var real_release_pos:Vector2 = (graph_edit.scroll_offset / graph_edit.zoom) + (release_position / graph_edit.zoom)
	from_graph_node = graph_edit.get_node(from)
	var slot_type = from_graph_node.get_slot_type_right(from_slot)
	add_popup.show_add_popup(slot_type, release_position)
	opened_popup_pos = real_release_pos
	use_popup_pos = true


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	graph_edit.disconnect_node(from, from_slot, to, to_slot)


func _on_PopupPanel_popup_hide():
	use_popup_pos = false
	from_graph_node = null


func _on_GraphEdit_gui_input(event:InputEventMouseButton):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		add_popup.show_add_popup(-1, get_global_mouse_position())
		opened_popup_pos = (graph_edit.scroll_offset / graph_edit.zoom) + (get_global_mouse_position() / graph_edit.zoom)
		use_popup_pos = true


func update_homescreen_list():
	homescreen_edit.clear()
	var item_id:= 0
	var sel_item_id:= 0
	for d in nodes:
		if d.res_name == "StepSection":
			homescreen_edit.add_item(d.section_name)
			if d.section_name == current_homescreen:
				sel_item_id = item_id
			item_id += 1
	homescreen_edit.select(sel_item_id)


func save_wizard_graph():
	var _data:Dictionary = {
		"info": {"script_name": "", "home_screen": ""},
		"nodes":{},
		"connections":{}
		}
	_data.info.script_name = script_edit.text
	_data.info.home_screen = current_homescreen
	
	for node in nodes:
		_data.nodes[node.step_id] = node.serialize()
	
	_data.connections = graph_edit.get_connection_list()
	
	if OS.has_feature("HTML5"):
		JavaScript.download_buffer(JSON.print(_data, "\t").to_utf8(), "%s.json" % [script_edit.text])
	else:
		save_json(file_path, file_name % script_edit.text, _data)


func load_wizard_graph(selected_file):
	data = load_json(file_path + selected_file)
	if data.empty():
		print("Error: Empty file at '%s'" % (file_path + selected_file))
		return
	
	for node in data.nodes.values():
		var new_step = add_step(node.res_name, node.id)
		new_step.deserialize(node)
	
	for c in data.connections:
		graph_edit.connect_node(c.from, c.from_port, c.to, c.to_port)
	
	script_edit.text = data.info.script_name
	current_homescreen = data.info.home_screen
	
	update_homescreen_list()


func _on_SaveGraph_pressed():
	_g.emit_signal("add_toast", 0, "Wizard Script saved!")
	save_wizard_graph()


func _on_LoadGraph_pressed():
	$ScriptSelection.show_scripts(file_path)


func _on_ScriptEdit_text_changed(new_text):
	var cp = script_edit.get_cursor_position()
	script_edit.text = new_text.dedent().to_lower().replace(" ", "_")
	script_edit.set_cursor_position(cp)
	


func _on_HomeScreenEdit_item_selected(index):
	current_homescreen = homescreen_edit.get_item_text(index)


func _on_ScriptSelection_open_script_file(_file_name:String):
	for n in nodes:
		n.queue_free()
	nodes.clear()
	graph_edit.clear_connections()
	yield(VisualServer, "frame_post_draw")
	yield(VisualServer, "frame_post_draw")
	yield(VisualServer, "frame_post_draw")
	load_wizard_graph(_file_name)


func _on_BackBtn_pressed():
	get_tree().change_scene("res://Main.tscn")
