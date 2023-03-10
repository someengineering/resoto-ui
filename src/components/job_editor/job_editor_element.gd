extends PanelContainer

enum Trigger {SCHEDULED, EVENT, SCHEDULED_AND_EVENT}

const HELP_TEXT_TRIGGER_INTRO := "The job trigger defines when a job is executed.\n\n"
const HELP_TEXT_TRIGGER_SCHEDULE := "[b]Schedule Trigger[/b]\nA schedule trigger executes a job at a specific time interval described by a cron expression."
const HELP_TEXT_TRIGGER_EVENT := "[b]Event Trigger[/b]\nAn event trigger executes a job when a specific event is emitted by Resoto.\n\nResoto updates the state of resources in the four steps of the collect_and_cleanup workflow: [code]collect[/code], [code]cleanup_plan[/code], [code]cleanup[/code], and [code]generate_metrics[/code].\n\nEach of these steps emits events that can be used to trigger jobs."
const HELP_TEXT_TRIGGER_COMBINED := "[b]Combined Trigger[/b]\nA combined trigger combines a schedule trigger with an event trigger, and executes a job when a specific event is emitted after a schedule trigger is fired.\n\nCombined triggers are useful if you want to perform an action on a specific schedule, but only after a specific event is fired."
const HELP_TEXT_TRIGGER_MORE := "\n\n[url=trigger_docs]Read more about triggers in the Resoto docs.[/url]"

const Trigger_Events : Array = [
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
signal duplicate_job
signal cron_editor
signal show_save_options
signal toggle_save_button
signal changed_active_state

var examples_triggers := [
	"[b]Event Triggers[/b]",
	{ "descr" : "After every Resoto Collect." , "job_trigger" : 1, "job_event" : "post_collect", "job_schedule" : ""},
	{ "descr" : "When Resoto cleans up resources marked for clean-up." , "job_trigger" : 1, "job_event" : "cleanup_plan", "job_schedule" : ""},
	"[b]Combined Triggers[/b]",
	{ "descr" : "Every morning, Mon-Fri at 5:00 after a Resoto Collect." , "job_trigger" : 2, "job_event" : "post_collect", "job_schedule" : "0 5 * * MON-FRI"},
	"[b]Scheduled Triggers[/b]",
	{ "descr" : "Every morning at 9:00 from Mon-Fri." , "job_trigger" : 0, "job_event" : "", "job_schedule" : "0 9 * * 1-5"},
	{ "descr" : "Every Friday evening at 22:00." , "job_trigger" : 0, "job_event" : "", "job_schedule" : "0 22 * * 5"},
	{ "descr" : "Every Monday morning at 5:00." , "job_trigger" : 0, "job_event" : "", "job_schedule" : "0 5 * * mon"},
	{ "descr" : "On the first Day of each Month." , "job_trigger" : 0, "job_event" : "", "job_schedule" : "0 0 1 * *"},
	{ "descr" : "Every six hours." , "job_trigger" : 0, "job_event" : "", "job_schedule" : "0 */6 * * *"}
]

var example_commands := [
	"[b]Alerting[/b]",
	{ "descr" : "Report Instances with >4Gb Ram in 'test-account' in a Discord message.", "command" : "search is(instance) and instance_memory>4 and /ancestors.account.reported.name==test-account | discord --title=\"Large instances found in test-account\" --webhook=\"https://your-webhook-url\"" },
	{ "descr" : "Find instances that have no owner tag and report them in a Discord message.", "command" : "search is(kubernetes_pod) and pod_status.container_statuses[*].restart_count > 20 and last_update<1h | discord --title=\"Pods are restarting too often!\" --webhook=\"https://your-webhook-url\""},
	{ "descr" : "Find Volumes and Buckets without a 'costcenter' tag and report them in a Discord message.", "command" : "search is(aws_ec2_volume) or is(aws_s3_bucket) and tags.costcenter = null | discord --title=\"Resources missing `costcenter` tag\" --webhook=\"https://your-webhook-url\""},
	"[b]Clean-up[/b]",
	{ "descr" : "Find unused AWS EBS Volumes that are older than a month and had no I/O in over a week.", "command" : "search is(aws_ec2_volume) and volume_status = available and age > 30d and last_access > 7d | clean \"Volume has not been used in a week\""},
	{ "descr" : "Mark expired Resources for cleanup.", "command" : "search /metadata.expires < \"@utc@\" | clean \"Resource is expired\""},
	"[b]Cost-saving[/b]",
	{ "descr" : "Shutdown running AWS EC2 instances and give them a shutdown-tag for restarting.", "command" : "search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name = someengineering-development | tag update shutdown_by resoto; search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | aws ec2 stop-instances --instance-ids {id}"},
	{ "descr" : "Startup AWS EC2 Instances with a certain shutdown-tag.", "command" : "search is(aws_ec2_instance) and instance_status=stopped and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | aws ec2 start-instances --instance-ids {id}; search is(aws_ec2_instance) and instance_status=stopped and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | tag delete shutdown_by"},
	{ "descr" : "Stop AWS Instances that have 'dev' in their name.", "command" : "search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name~dev | aws ec2 stop-instances --instance-ids {id}"},
]

var job_id : String			= "" setget set_job_id
var job_active : bool		= true setget set_job_active
var job_command : String	= "" setget set_job_command
var job_trigger : int		= Trigger.EVENT setget set_job_trigger
var job_event : String		= "" setget set_job_event
var job_schedule : String	= "0 * * * *" setget set_job_schedule
var job_is_new : bool		= false

onready var event_popup : PopupMenu = $"%EventSelector".get_popup()
onready var cron_regex : RegEx = RegEx.new()
onready var trigger_help_text := $"%TriggerHelpText"
onready var command_edit := $"%CommandEdit"


func _ready():
	cron_regex.compile("(^((\\*\\/)?([0-5]?[0-9])((\\,|\\-|\\/)([0-5]?[0-9]))*|\\*)\\s+((\\*\\/)?((2[0-3]|1[0-9]|[0-9]|00))((\\,|\\-|\\/)(2[0-3]|1[0-9]|[0-9]|00))*|\\*)\\s+((\\*\\/)?([1-9]|[12][0-9]|3[01])((\\,|\\-|\\/)([1-9]|[12][0-9]|3[01]))*|\\*)\\s+((\\*\\/)?([1-9]|1[0-2])((\\,|\\-|\\/)([1-9]|1[0-2]))*|\\*|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)((\\,|\\-|\\/)(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))*)\\s+((\\*\\/)?[0-6]((\\,|\\-|\\/)[0-6])*|\\*|00|(mon|tue|wed|thu|fri|sat|sun)((\\,|\\-|\\/)(mon|tue|wed|thu|fri|sat|sun))*)$)")
	event_popup.connect("id_pressed", self, "_on_event_selected")
	for trigger_event in Trigger_Events:
		if trigger_event.separator:
			event_popup.add_separator(trigger_event.id)
		else:
			event_popup.add_radio_check_item(trigger_event.id)
	# Create Examples Richtext for Triggers
	var examples_string := ""
	for i in examples_triggers.size():
		if typeof(examples_triggers[i]) == TYPE_STRING:
			examples_string += "\n" + examples_triggers[i] + "\n"
		else:
			examples_string += "• [url=%s]%s[/url]\n" % [i, examples_triggers[i].descr]
	examples_string = examples_string.trim_suffix("\n").trim_prefix("\n")
	$"%ExamplesHelpText".bbcode_text = examples_string
	# Create Examples Richtext for Commands
	var examples_string_cmd := ""
	for i in example_commands.size():
		if typeof(example_commands[i]) == TYPE_STRING:
			examples_string_cmd += "\n" + example_commands[i] + "\n"
		else:
			examples_string_cmd += "• [url=%s]%s[/url]\n" % [i, example_commands[i].descr]
	examples_string_cmd = examples_string_cmd.trim_suffix("\n").trim_prefix("\n")
	$"%CommandExamplesText".bbcode_text = examples_string_cmd


func setup_new_job():
	job_is_new = true
	$"%JobID".show()
	$"%JobNameEdit".show()
	$"%JobNameEdit".grab_focus()
	$"%JobName".hide()
	$"%JobNameSpacer".hide()
	show_command_error(true)
	yield(VisualServer, "frame_post_draw")
	$"%JobNameEdit".set_cursor_position(job_id.length())
	$"%RunButton".hide()
	$"%DuplicateButton".hide()
	$"%DeleteButton".hide()


func show_command_error(_show:bool):
	if _show == $"%CommandError".visible:
		return
	$"%CommandError".visible = _show
	emit_signal("toggle_save_button", _show)


func show_save_options():
	emit_signal("show_save_options", job_is_new)


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
	if job_data.has("is_new_job"):
		setup_new_job()
	self.job_id = job_data.id
	self.job_active = job_data.active
	self.job_command = job_data.command
	show_command_error(command_edit.text == "")
	var temp_job_trigger = -1
	if job_data.has("trigger"):
		if job_data.trigger.has("cron_expression"):
			# has schedule
			temp_job_trigger = 0
			self.job_schedule = job_data.trigger.cron_expression
		elif job_data.trigger.has("message_type"):
			# event trigger
			temp_job_trigger = 1
			job_event = job_data.trigger.message_type
			_on_event_selected(get_event_id_from_string(job_data.trigger.message_type))
			
	if job_data.has("wait"):
		# has schedule, then wait for event
		temp_job_trigger = 2
		job_event = job_data.wait.message_type
		_on_event_selected(get_event_id_from_string(job_data.wait.message_type))
	self.job_trigger = temp_job_trigger


func set_job_id(_job_id:String):
	job_id = _job_id
	$"%JobName".text = job_id
	$"%JobNameEdit".text = job_id


func set_job_active(_job_active:bool):
	job_active = _job_active
	modulate.a = 1.0 if job_active else 0.8
	$"%ActiveButton".pressed = job_active
	$"%ActiveButton"._on_toggle(job_active)


func set_job_command(_job_command:String):
	job_command = _job_command
	command_edit.text = job_command


func set_job_trigger(_job_trigger:int):
	job_trigger = _job_trigger
	$"%TriggerSelect".selected = job_trigger
	$"%CronLabel".visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%CronContainer".visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%EventLabel".visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$"%EventSelector".visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	update_help_text_trigger(_job_trigger)


func set_job_event(_job_event:String):
	job_event = _job_event
	$"%EventSelector".text = job_event


func set_job_schedule(_job_schedule:String):
	job_schedule = _job_schedule
	$"%CronLineEdit".text = job_schedule
	$"%CronError".visible = cron_regex.search_all(job_schedule.to_lower()).empty()


func get_event_id_from_string(_job_event:String) -> int:
	for item_id in event_popup.get_item_count():
		if event_popup.get_item_text(item_id) == _job_event:
			return item_id
	return -1


func _on_CommandEdit_text_changed():
	show_command_error(command_edit.text == "")
	if command_edit.text != job_command:
		show_save_options()


func _on_TriggerSelect_item_selected(index:int):
	if index != job_trigger:
		show_save_options()
	
	$"%CronLabel".visible = index != Trigger.EVENT
	$"%CronContainer".visible = index != Trigger.EVENT
	$"%EventLabel".visible = index != Trigger.SCHEDULED
	$"%EventSelector".visible = index != Trigger.SCHEDULED
	
	# If there is no event defined yet, choose the cleanup_plan event
	if index != Trigger.SCHEDULED and job_event == "":
		for item_id in event_popup.get_item_count():
			if event_popup.is_item_radio_checkable(item_id):
				event_popup.set_item_checked(item_id, false)
		event_popup.set_item_checked(4, true)
		$"%EventSelector".text = "cleanup_plan"
	update_help_text_trigger(index)


func update_help_text_trigger(trigger_id:int):
	var trigger_help_string = HELP_TEXT_TRIGGER_INTRO
	match trigger_id:
		Trigger.SCHEDULED:
			trigger_help_string += HELP_TEXT_TRIGGER_SCHEDULE
		Trigger.EVENT:
			trigger_help_string += HELP_TEXT_TRIGGER_EVENT
		Trigger.SCHEDULED_AND_EVENT:
			trigger_help_string += HELP_TEXT_TRIGGER_COMBINED
	trigger_help_string += HELP_TEXT_TRIGGER_MORE
	trigger_help_text.bbcode_text = trigger_help_string


func _on_CronLineEdit_text_changed(new_text:String):
	if new_text != job_schedule:
		show_save_options()
	$"%CronError".visible = cron_regex.search_all(new_text.to_lower()).empty()


func _on_ActiveButton_pressed():
	if not job_is_new:
		if job_active:
			API.cli_execute("jobs deactivate %s" % job_id, self, "_on_job_active_toggle_done")
		else:
			API.cli_execute("jobs activate %s" % job_id, self, "_on_job_active_toggle_done")
	self.job_active = !job_active


func _on_RunButton_pressed():
	Analytics.event(Analytics.EventsJobEditor.RUN)
	_g.emit_signal("resh_lite_popup_with_cmd", "jobs run %s" % job_id)


func _on_DuplicateButton_pressed():
	emit_signal("duplicate_job", generate_dict())
	return
	var copy_job_trigger : int = $"%TriggerSelect".get_selected_id()
	var copy_job_schedule : String = $"%CronLineEdit".text
	var copy_job_event : String = $"%EventSelector".text
	var copy_trigger_string : String = generate_schedule_string(copy_job_trigger, copy_job_schedule, copy_job_event)
	var copy_job_command : String = command_edit.text
	emit_signal("duplicate_job", job_id, copy_trigger_string, copy_job_command)


func generate_dict() -> Dictionary:
	var job_dict : Dictionary = {
		"active" : true,
		"command" : command_edit.text,
		"id" : job_id + "-duplicate",
		"trigger" : {},
		"is_new_job" : true
	}
	if job_trigger == Trigger.SCHEDULED:
		job_dict.trigger = { "cron_expression" : job_schedule }
	elif job_trigger == Trigger.EVENT:
		job_dict.trigger = { "message_type" : job_event }
	elif job_trigger == Trigger.SCHEDULED_AND_EVENT:
		job_dict.trigger = { "cron_expression" : job_schedule }
		job_dict["wait"] = { "message_type" : job_event }
	return job_dict


func id_warning():
	$"%IdError".show()


func _on_DeleteButton_pressed():
	var delete_confirm_popup = _g.popup_manager.show_confirm_popup(
		"Delete Job?",
		"Do you want to delete the following job:\n`%s`\n\nThis operation can not be undone!" % job_id,
		"Delete", "Cancel")
	delete_confirm_popup.connect("response", self, "_on_delete_confirm_response", [], CONNECT_ONESHOT)


func _on_delete_confirm_response(_response:String, _double_confirm:=false):
	if _response == "left":
		API.cli_execute("jobs delete %s" % job_id, self, "_on_job_delete_done")
		Analytics.event(Analytics.EventsJobEditor.DELETE)


func _on_job_delete_done(_e, _r):
	emit_signal("delete_job", self)


func _on_job_active_toggle_done(_e, _r):
	if not _e:
		emit_signal("changed_active_state", job_id, job_active)


func _on_job_run_done(_e, _r):
	pass


func save_field():
	job_trigger = $"%TriggerSelect".get_selected_id()
	job_schedule = $"%CronLineEdit".text
	job_event = $"%EventSelector".text
	
	if job_is_new:
		$"%JobNameEdit".text = Utils.slugify($"%JobNameEdit".text)
		job_id = $"%JobNameEdit".text
	
	var trigger_string : String = generate_schedule_string(job_trigger, job_schedule, job_event)
	
	job_command = command_edit.text
	return [job_id, trigger_string, job_command]


func generate_schedule_string(_trigger_type:int, trigger_schedule:String, trigger_event:String) -> String:
	var _trigger_string := ""
	if _trigger_type == Trigger.SCHEDULED or _trigger_type == Trigger.SCHEDULED_AND_EVENT:
		_trigger_string = "--schedule \"%s\"" % trigger_schedule
		if _trigger_type == Trigger.SCHEDULED_AND_EVENT:
			_trigger_string += " --wait-for-event %s" % trigger_event
	elif _trigger_type == Trigger.EVENT:
		_trigger_string = "--wait-for-event %s" % trigger_event
	return _trigger_string


func _on_CronEditor_pressed():
	emit_signal("cron_editor", $"%CronContainer".get_global_rect(), $"%CronLineEdit".text, $"%CronLineEdit")


func _on_HelpButton_pressed():
	$"%HelpButton".pressed = true
	$"%HelpButton".release_focus()
	$"%ExamplesButton".pressed = false
	$"%TriggerHelpText".show()
	$"%ExamplesHelpText".hide()
	

func _on_ExamplesButton_pressed():
	$"%HelpButton".pressed = false
	$"%ExamplesButton".pressed = true
	$"%ExamplesButton".release_focus()
	$"%TriggerHelpText".hide()
	$"%ExamplesHelpText".show()


func _on_ExamplesHelpText_meta_clicked(meta):
	if meta == "trigger_docs":
		OS.shell_open("https://resoto.com/docs/concepts/automation#job-trigger")
		return
	var example : Dictionary = examples_triggers[int(meta)]
	$"%TriggerSelect".select(example.job_trigger)
	_on_TriggerSelect_item_selected(example.job_trigger)
	update_help_text_trigger(example.job_trigger)
	
	if example.job_trigger != 0:
		_on_event_selected(get_event_id_from_string(example.job_event))
		job_event = example.job_event
	if example.job_schedule != "":
		$"%CronLineEdit".text = example.job_schedule


func _on_CommandsHelpButton_pressed():
	$"%CommandsHelpButton".pressed = true
	$"%CommandsHelpButton".release_focus()
	$"%CommandsExamplesButton".pressed = false
	$"%CommandHelpText".show()
	$"%CommandExamplesText".hide()


func _on_CommandsExamplesButton_pressed():
	$"%CommandsHelpButton".pressed = false
	$"%CommandsExamplesButton".pressed = true
	$"%CommandsExamplesButton".release_focus()
	$"%CommandHelpText".hide()
	$"%CommandExamplesText".show()


func _on_CommandExamplesText_meta_clicked(meta):
	if meta == "trigger_docs":
		OS.shell_open("https://resoto.com/docs/concepts/automation#job-filters--actions")
		return
	var example : Dictionary = example_commands[int(meta)]
	command_edit.text = example.command
	show_command_error(false)


func _on_JobNameEdit_focus_exited():
	$"%JobNameEdit".text = Utils.slugify($"%JobNameEdit".text)


func _on_JobNameEdit_text_entered(new_text):
	$"%JobNameEdit".text = Utils.slugify($"%JobNameEdit".text)
	$"%JobNameEdit".release_focus()


func _on_JobNameEdit_text_changed(new_text):
	$"%IdError".hide()
