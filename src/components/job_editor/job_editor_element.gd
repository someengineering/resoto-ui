extends PanelContainer

enum Trigger {SCHEDULED, EVENT, SCHEDULED_AND_EVENT}

const Trigger_Events = [
	{
		"id" : "Collect Steps",
		"separator" : true
	},
	{
		"id" : "pre_collect",
		"separator" : false
	},
	{
		"id" : "collect",
		"separator" : false
	},
	{
		"id" : "merge_outer_edges",
		"separator" : false
	},
	{
		"id" : "post_collect",
		"separator" : false
	},
	{
		"id" : "Cleanup Steps",
		"separator" : true
	},
	{
		"id" : "pre_cleanup_plan",
		"separator" : false
	},
	{
		"id" : "cleanup_plan",
		"separator" : false
	},
	{
		"id" : "post_cleanup_plan",
		"separator" : false
	},
	{
		"id" : "pre_cleanup",
		"separator" : false
	},
	{
		"id" : "cleanup",
		"separator" : false
	},
	{
		"id" : "post_cleanup",
		"separator" : false
	},
	{
		"id" : "Metrics Steps",
		"separator" : true
	},
	{
		"id" : "pre_generate_metrics",
		"separator" : false
	},
	{
		"id" : "generate_metrics",
		"separator" : false
	},
	{
		"id" : "post_generate_metrics",
		"separator" : false
	},
]

signal delete_job

var job_id : String			= "" setget set_job_id
var job_active : bool		= true setget set_job_active
var job_command : String	= "" setget set_job_command
var job_trigger : int		= Trigger.SCHEDULED setget set_job_trigger
var job_event : String		= "" setget set_job_event
var job_schedule : String	= "* * * * *" setget set_job_schedule

onready var event_popup : PopupMenu = $"%EventSelector".get_popup()


func _ready():
	event_popup.connect("id_pressed", self, "_on_event_selected")
	for trigger_event in Trigger_Events:
		if trigger_event.separator:
			event_popup.add_separator(trigger_event.id)
		else:
			event_popup.add_radio_check_item(trigger_event.id)


func show_save_options():
	$"%SaveDiscardBar".show()
	$"%SaveDiscardSpacer".show()


func hide_save_options():
	$"%SaveDiscardBar".hide()
	$"%SaveDiscardSpacer".hide()


func _on_event_selected(_id:int):
	for item_id in event_popup.get_item_count():
		if event_popup.is_item_radio_checkable(item_id):
			event_popup.set_item_checked(item_id, false)
	event_popup.set_item_checked(_id, true)
	
	if event_popup.get_item_text(_id) != job_event:
		show_save_options()
	
	self.job_event = event_popup.get_item_text(_id)


func restore_from_core() -> void:
	API.cli_execute_json("jobs show %s" % job_id, self, "_on_job_show_data", "_on_job_show_done" )


func _on_job_show_data(_e, _d):
	pass


func _on_job_show_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in Job refresh", Utils.err_enum_to_string(_error), 1, self)
		return
	if _response.transformed.has("result"):
		for job in _response.transformed.result:
			setup(job)
			return


func setup(job_data) -> void:
	self.job_id = job_data.id
	self.job_active = job_data.active
	self.job_command = job_data.command
	var temp_job_trigger = -1
	if job_data.has("trigger"):
		if job_data.trigger.has("cron_expression"):
			# has schedule
			temp_job_trigger = 0
			self.job_schedule = job_data.trigger.cron_expression
		elif job_data.trigger.has("message_type"):
			# event trigger
			temp_job_trigger = 1
			_on_event_selected(get_event_id_from_string(job_data.trigger.message_type))
			
	if job_data.has("wait"):
		# has schedule, then wait for event
		temp_job_trigger = 2
		_on_event_selected(get_event_id_from_string(job_data.wait.message_type))
	self.job_trigger = temp_job_trigger
	hide_save_options()


func set_job_id(_job_id:String):
	job_id = _job_id
	$"%JobName".text = job_id


func set_job_active(_job_active:bool):
	job_active = _job_active
	modulate.a = 1.0 if job_active else 0.6
	$"%ActiveButton".pressed = job_active
	$"%ActiveButton"._on_toggle(job_active)


func set_job_command(_job_command:String):
	job_command = _job_command
	$"%CommandEdit".text = job_command


func set_job_trigger(_job_trigger:int):
	job_trigger = _job_trigger
	$"%TriggerSelect".selected = job_trigger
	$"%CronLabel".visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%CronLineEdit".visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%EventLabel".visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%EventSelector".visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)


func set_job_event(_job_event:String):
	job_event = _job_event
	$"%EventSelector".text = job_event


func set_job_schedule(_job_schedule:String):
	job_schedule = _job_schedule
	$"%CronLineEdit".text = job_schedule


func get_event_id_from_string(_job_event:String) -> int:
	for item_id in event_popup.get_item_count():
		if event_popup.get_item_text(item_id) == _job_event:
			return item_id
	return -1


func _on_CommandEdit_text_changed():
	if $"%CommandEdit".text != job_command:
		show_save_options()


func _on_TriggerSelect_item_selected(index:int):
	if index != job_trigger:
		show_save_options()
	
	$"%CronLabel".visible = index != Trigger.EVENT
	$"%CronLineEdit".visible = index != Trigger.EVENT
	$"%EventLabel".visible = index != Trigger.SCHEDULED
	$"%EventSelector".visible = index != Trigger.SCHEDULED
	
	# If there is no event defined yet, choose the post_collect event
	if index != Trigger.SCHEDULED and job_event == "":
		for item_id in event_popup.get_item_count():
			if event_popup.is_item_radio_checkable(item_id):
				event_popup.set_item_checked(item_id, false)
		event_popup.set_item_checked(4, true)
		$"%EventSelector".text = "post_collect"


func _on_CronLineEdit_text_changed(new_text:String):
	if new_text != job_schedule:
		show_save_options()


func _on_ActiveButton_pressed():
	if job_active:
		API.cli_execute("jobs deactivate %s" % job_id, self, "_on_job_active_toggle_done")
	else:
		API.cli_execute("jobs activate %s" % job_id, self, "_on_job_active_toggle_done")
	self.job_active = !job_active


func _on_RunButton_pressed():
	API.cli_execute("jobs run %s" % job_id, self, "_on_job_run_done")


func _on_DeleteButton_pressed():
	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		"Delete Job?",
		"Do you want to delete the following job:\n`%s`\n\nThis operation can not be undone!" % job_id,
		"Delete", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String, _double_confirm:=false):
	if _response == "left":
		API.cli_execute("jobs delete %s" % job_id, self, "_on_job_delete_done")


func _on_job_delete_done():
	emit_signal("delete_job", self)


func _on_job_active_toggle_done(_e, _r):
	pass


func _on_job_run_done(_e, _r):
	pass


func _on_SaveButton_pressed():
	job_trigger = $"%TriggerSelect".get_selected_id()
	job_schedule = $"%CronLineEdit".text
	job_command = $"%CommandEdit".text
	job_event = $"%EventSelector".text
	
	var trigger_string := ""
	if job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT:
		trigger_string = "--schedule \"%s\"" % job_schedule
		if job_trigger == Trigger.SCHEDULED_AND_EVENT:
			trigger_string += " --wait-for-event %s" % job_event
	elif job_trigger == Trigger.EVENT:
		trigger_string = "--wait-for-event %s" % job_event
	
	API.cli_execute("jobs update --id %s %s '%s'" % [job_id, trigger_string, job_command], self, "_on_job_update_done")
	hide_save_options()


func _on_job_update_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in Job update", _response.body.get_string_from_utf8(), 1, self)
		return


func _on_DiscardButton_pressed():
	restore_from_core()
