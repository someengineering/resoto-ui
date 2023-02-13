extends Control

signal started
signal message_new
signal progress_message
signal all_done

const ProgressElement = preload("res://components/collect_run_display/collect_run_display_progress_element.tscn")

enum Kinds {EVENT, ACTION}
enum MessageTypes {TASK_STARTED, PROGRESS, ERROR, MERGE_OUTER_EDGES, POST_COLLECT, PRE_GENERATE_METRICS, GENERATE_METRICS, TASK_END}

export (bool) var test_mode := false
export (bool) var test_mode_manual := false
export (bool) var wait_for_task_started := true

const message_types : Dictionary = {
	MessageTypes.TASK_STARTED : "task_started",
	MessageTypes.PROGRESS : "progress",
	MessageTypes.ERROR : "error",
	MessageTypes.MERGE_OUTER_EDGES : "merge_outer_edges",
	MessageTypes.POST_COLLECT : "post_collect",
	MessageTypes.PRE_GENERATE_METRICS : "pre_generate_metrics",
	MessageTypes.GENERATE_METRICS : "generate_metrics",
	MessageTypes.TASK_END : "task_end"
}

var full_run_events := []
var run_errors := []
var run_error_count := 0
var error_string : String = ""
var mouse_on_errors := false
var display_messages := false

onready var elements := $PanelContainer/Content/ScrollContainer/Content/Elements


# Structure of a message:
#	message_type : see enum,
#	kind : see enum,
#	data : { 
#		workflow	: workflow name.. eg. "collect", 
#		task		: "TASK UID",
#		step		: only relevant for kind = action - the name of the step,
#		message		: ""
#	}


func _ready():
	if not wait_for_task_started:
		display_messages = true
	
	if test_mode:
		start_test()
	else:
		_g.connect("websocket_message", self, "receive_websocket_message")


func update_title_text(_new:String):
	$PanelContainer/Content/HBoxContainer/Label.text = _new


func receive_websocket_message(_m:String):
	if _m == "":
		return
	var json_res : JSONParseResult = JSON.parse(_m)
	if json_res.result:
		parse_message(json_res.result)


func wait_for_config_update():
	refresh_elements()
	$PanelContainer/Content/HBoxContainer/Done.hide()
	var new_progress_element = ProgressElement.instance().init("Waiting for configuration update.", 1, 0)
	elements.add_child(new_progress_element)
	display_messages = false


func wait_for_core():
	refresh_elements()
	$PanelContainer/Content/HBoxContainer/Done.hide()
	var new_progress_element = ProgressElement.instance().init("Waiting for Resoto Core to finish other workflows...", 1, 0)
	elements.add_child(new_progress_element)
	display_messages = false
	$CheckForWorkflows.start()


func _on_CheckForWorkflows_timeout():
	if not display_messages:
		API.cli_execute("workflow running", self)


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		return
	if not display_messages:
		var workflow_running_name : String = _response.transformed.result.split("\n")[0]
		var new_progress_element = ProgressElement.instance().init("Running " + workflow_running_name, 1, 0)
		elements.add_child(new_progress_element)


func refresh_elements():
	elements.queue_free()
	var new_elements : VBoxContainer = VBoxContainer.new()
	new_elements.rect_min_size = Vector2(1, 1)
	$PanelContainer/Content/ScrollContainer/Content.add_child(new_elements)
	elements = new_elements


func refresh_error_tooltip():
	if run_errors.empty():
		$PanelContainer/Content/HBoxContainer/ErrorBtn.hide()
		$PanelContainer/Content/HBoxContainer/ErrorNumber.hide()
		return
		
	$PanelContainer/Content/HBoxContainer/ErrorBtn.show()
	$PanelContainer/Content/HBoxContainer/ErrorNumber.show()
	$PanelContainer/Content/HBoxContainer/ErrorNumber.text = str(run_error_count)
	$PanelContainer/Content/HBoxContainer/ErrorNumber.rect_size.x = 1
	
	error_string = ""
	for e in run_errors:
		error_string += e + "\n"
	error_string = error_string.trim_suffix("\n")
	$ErrorPopup/MarginContainer/AllErrorsGroup.node_text = error_string


func parse_message(_m:Dictionary):
	if test_mode:
		print(Utils.readable_dict(_m))
	var m_type : String = _m.message_type
	if not display_messages and m_type != message_types[MessageTypes.TASK_STARTED]:
		return
	
	if m_type == message_types[MessageTypes.TASK_STARTED]:
		$CheckForWorkflows.stop()
		emit_signal("started")
		run_errors.clear()
		run_error_count = 0
		refresh_error_tooltip()
		refresh_elements()
		$PanelContainer/Content/HBoxContainer/Done.hide()
		var new_progress_element = ProgressElement.instance().init("Starting Task", 1, 0)
		elements.add_child(new_progress_element)
		display_messages = true
	
	elif m_type == message_types[MessageTypes.ERROR]:
		# handle error
		if _m.data.has("message"):
			run_error_count += 1
			if run_errors.size() < 100:
				run_errors.append(_m.data.message)
			var properties := {"error" : _m.data.message}
			Analytics.event(Analytics.EventWizard.ERROR, properties)
			refresh_error_tooltip()
	
	elif m_type == message_types[MessageTypes.PROGRESS]:
		# handle progress
		var msg : Dictionary = {}
		if _m.data.has("message"):
			msg = _m.data.message
		else:
			return
		emit_signal("progress_message")
		refresh_elements()
		for p in msg.parts:
			var part_parent : Node = elements
			var new_progress_element = ProgressElement.instance().init(p.name, p.total, p.current)
			
			if p.has("path"):
				part_parent = find_or_create_parent(p.path, elements)
			
			if part_parent.has_method("add_sub_element"):
				part_parent.add_sub_element(new_progress_element)
			else:
				part_parent.add_child(new_progress_element)
	elif m_type == message_types[MessageTypes.TASK_END]:
		refresh_elements()
		$PanelContainer/Content/HBoxContainer/Done.show()
		var new_progress_element = ProgressElement.instance().init("Finished!", 1, 1)
		_g.emit_signal("collect_run_finished")
		elements.add_child(new_progress_element)
		emit_signal("all_done", run_errors.empty())
		display_messages = false
	else:
		if _m.data.has("step"):
			emit_signal("message_new")
			refresh_elements()
			var new_progress_element = ProgressElement.instance().init(_m.data.step, 1, 0)
			elements.add_child(new_progress_element)


func find_or_create_parent(_path:Array, par:Node) -> Node:
	for p in _path:
		var new_par : Node = null
		if par.has_method("get_sub_element"):
			var par_sub_element : Node = par.get_sub_element()
			new_par = par_sub_element.get_node_or_null(p)
		else:
			new_par = par.get_node_or_null(p)
		
		if new_par == null:
			var new_progress_element = ProgressElement.instance().init(p, 1, 0)
			if run_errors.has(p):
				new_progress_element.has_errors = true
			if par.has_method("add_sub_element"):
				par.add_sub_element(new_progress_element)
			else:
				par.add_child(new_progress_element)
			par = new_progress_element
		else:
			par = new_par
	return par


func _on_Button_pressed():
	$Flip.start()


func _on_ErrorBtn_pressed():
	$ErrorPopup/MarginContainer/AllErrorsGroup.show()


func start_test():
	var path := "res://data/test_data/websocket_workflow_collect_run.txt"
	var file : File = File.new()
	if !file.file_exists(path):
		return []
	file.open(path, file.READ)
	var full_run_txt : String = file.get_as_text()
	file.close()
	
	var t_full_run_events : Array = full_run_txt.split("\n")
	for tfe in t_full_run_events:
		if tfe == "":
			continue
		var jr : JSONParseResult = JSON.parse(tfe)
		if !jr.error:
			full_run_events.append(jr.result)
	if not test_mode_manual:
		$Flip.start()
	else:
		parse_message(full_run_events[0])

# commented out so it doesn't trigger all the time.
# Can be uncommented to manually test.
#func _input(event):
#	if not test_mode_manual:
#		return
#	if event.is_action_pressed("ui_right"):
#		full_run_events_id = int(clamp(full_run_events_id+1, 0, full_run_events.size()))
#		parse_message(full_run_events[full_run_events_id])
#	if event.is_action_pressed("ui_left"):
#		full_run_events_id = int(clamp(full_run_events_id-1, 0, full_run_events.size()))
#		parse_message(full_run_events[full_run_events_id])


var full_run_events_id := 0
func _on_Flip_timeout():
	parse_message(full_run_events[full_run_events_id])
	full_run_events_id += 1
	if full_run_events_id == full_run_events.size():
		$Flip.stop()
	else:
		$Flip.wait_time = rand_range(0.1, 0.2)
		$Flip.start()
