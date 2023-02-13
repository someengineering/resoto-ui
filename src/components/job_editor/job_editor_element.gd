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

var job_id : String			= "" setget set_job_id
var job_active : bool		= true setget set_job_active
var job_command : String	= "" setget set_job_command
var job_trigger : int		= Trigger.SCHEDULED setget set_job_trigger
var job_event : String		= "post_collect" setget set_job_event
var job_schedule : String	= "* * * * *" setget set_job_schedule
var is_dirty : bool			= false

onready var event_popup : PopupMenu = $JobData/TriggerSection/EventSelector.get_popup()


func _ready():
	event_popup.connect("id_pressed", self, "_on_event_selected")
	for trigger_event in Trigger_Events:
		if trigger_event.separator:
			event_popup.add_separator(trigger_event.id)
		else:
			event_popup.add_radio_check_item(trigger_event.id)


func _on_event_selected(_id:int):
	for item_id in event_popup.get_item_count():
		if event_popup.is_item_radio_checkable(item_id):
			event_popup.set_item_checked(item_id, false)
	event_popup.set_item_checked(_id, true)
	self.job_event = event_popup.get_item_text(_id)


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


func set_job_id(_job_id:String):
	job_id = _job_id
	$JobData/TitleBar/JobName.text = job_id


func set_job_active(_job_active:bool):
	job_active = _job_active
	$JobData/TitleBar/ActiveButton.pressed = job_active
	$JobData/TitleBar/ActiveButton._on_toggle(job_active)


func set_job_command(_job_command:String):
	job_command = _job_command
	$JobData/CommandEdit.text = job_command


func set_job_trigger(_job_trigger:int):
	job_trigger = _job_trigger
	$JobData/TriggerSection/TriggerSelect.selected = job_trigger
	$JobData/TriggerSection/CronLabel.visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$JobData/TriggerSection/CronLineEdit.visible = (job_trigger == Trigger.SCHEDULED or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$JobData/TriggerSection/EventLabel.visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)
	$JobData/TriggerSection/EventSelector.visible = (job_trigger == Trigger.EVENT or job_trigger == Trigger.SCHEDULED_AND_EVENT)


func set_job_event(_job_event:String):
	prints("bla", _job_event)
	job_event = _job_event
	$JobData/TriggerSection/EventSelector.text = job_event


func set_job_schedule(_job_schedule:String):
	job_schedule = _job_schedule
	$JobData/TriggerSection/CronLineEdit.text = job_schedule


func get_event_id_from_string(_job_event:String) -> int:
	for item_id in event_popup.get_item_count():
		if event_popup.get_item_text(item_id) == _job_event:
			return item_id
	return -1


func _on_ActiveButton_pressed():
	pass # Replace with function body.


func _on_RunButton_pressed():
	pass # Replace with function body.


func _on_DeleteButton_pressed():
	pass # Replace with function body.


func _on_CommandEdit_text_changed():
	pass # Replace with function body.
