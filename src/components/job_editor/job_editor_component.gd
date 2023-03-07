extends Control

const JobElement = preload("res://components/job_editor/job_editor_element.tscn")
const NewJob : Dictionary = {
	"active" : true,
	"command" : "",
	"id" : "",
	"trigger" : { "cron_expression" : "0 * * * *" }
}
const template_jobs : Array = [
	{
		"name" : "large-instance-in-test-account",
		"descr" : "Report Instances with >4Gb Ram in 'test-account' every morning at 9am from Mon-Fri in a Discord message.",
		"command" : "search is(instance) and instance_memory>4 and /ancestors.account.reported.name==test-account | discord --title=\"Large instances found in test-account\" --webhook=\"https://your-webhook-url\"",
		"trigger_schedule" : "0 9 * * 1-5"
	},
	{
		"name" : "alert-on-pod-failure",
		"descr" : "Find instances that have no owner tag and report them in a Discord message.",
		"command" : "search is(kubernetes_pod) and pod_status.container_statuses[*].restart_count > 20 and last_update<1h | discord --title=\"Pods are restarting too often!\" --webhook=\"https://your-webhook-url\"",
		"trigger_event" : "post_collect"
	},
	{
		"name" : "aws-tgif",
		"descr" : "Stop AWS Instances on Friday evening that have 'dev' in their name.",
		"trigger_schedule" : "0 22 * * 5",
		"command" : "search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name~dev | aws ec2 stop-instances --instance-ids {id}"
	},
	{
		"name" : "notify-missing-tags",
		"descr" : "Find Volumes and Buckets without a 'costcenter' tag and report them in a Discord message.",
		"trigger_event" : "post_collect",
		"command" : "search is(aws_ec2_volume) or is(aws_s3_bucket) and tags.costcenter = null | discord --title=\"Resources missing `costcenter` tag\" --webhook=\"https://your-webhook-url\""
	},
	{
		"name" : "cleanup-unused-aws-ebs-volumes",
		"descr" : "Find unused AWS EBS Volumes that are older than a month and had no I/O in over a week.",
		"trigger_event" : "cleanup_plan",
		"command" : "search is(aws_ec2_volume) and volume_status = available and age > 30d and last_access > 7d | clean \"Volume has not been used in a week\""
	},
	{
		"name" : "cleanup-expired-resources",
		"descr" : "Mark expired Resources for cleanup.",
		"trigger_event" : "cleanup_plan",
		"command" : "search /metadata.expires < \"@utc@\" | clean \"Resource is expired\""
	},
	{
		"name" : "shutdown-and-tag-on-friday",
		"descr" : "Shutdown on Friday Evening and give the resources a shutdown-tag for restarting.",
		"trigger_event" : "post_collect",
		"trigger_schedule" : "0 5 * * sat",
		"command" : "search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name = someengineering-development | tag update shutdown_by resoto; search is(aws_ec2_instance) and instance_status=running and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | aws ec2 stop-instances --instance-ids {id}"
	},
	{
		"name" : "restart-tagged-resources-on-monday",
		"descr" : "Startup Instances with a certain shutdown-tag on Monday Morning.",
		"trigger_event" : "post_collect",
		"trigger_schedule" : "0 5 * * mon",
		"command" : "search is(aws_ec2_instance) and instance_status=stopped and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | aws ec2 start-instances --instance-ids {id}; search is(aws_ec2_instance) and instance_status=stopped and /ancestors.account.reported.name = someengineering-development and tags.shutdown_by = resoto | tag delete shutdown_by"
	}
]

var buffered_jobs := {}
var latest_added_job_id := ""
var job_tree_root : TreeItem = null

onready var template_popup := $TemplatePopup
onready var job_tree := $"%JobListTree"


func _ready():
	add_templates()


func _on_jobs_list_data(_e, _d):
	pass


func add_templates():
	for template_job in template_jobs:
		var new_button : Button = Button.new()
		new_button.text = template_job.descr
		new_button.align = Button.ALIGN_LEFT
		$"%TemplateContent".add_child(new_button)
		new_button.connect("pressed", self, "_on_job_template_button_pressed", [template_job])


func _on_job_template_button_pressed(job:Dictionary):
	var trigger_string := ""
	if job.has("trigger_schedule"):
		trigger_string = "--schedule \"%s\"" % job.trigger_schedule
	elif job.has("trigger_event"):
		trigger_string = "--wait-for-event %s" % job.trigger_event
	latest_added_job_id = job.name
	API.cli_execute("jobs add --id %s %s '%s'" % [job.name, trigger_string, job.command], self, "_on_job_add_done")
	Analytics.event(Analytics.EventsJobEditor.NEW_FROM_TEMPLATE)
	template_popup.hide()


func update_view():
	buffered_jobs.clear()
	API.cli_execute_json("jobs list", self, "_on_jobs_list_data", "_on_jobs_list_done" )


func _on_jobs_list_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in Job List display", Utils.err_enum_to_string(_error), 1, self)
		return
	if _response.transformed.has("result"):
		buffered_jobs.clear()
		for job in _response.transformed.result:
			create_job_element(job)


func create_job_element(job:Dictionary) -> void:
	buffered_jobs[job.id] = job
	update_navigation()


func update_navigation(_filter:=""):
	job_tree.clear()
	job_tree_root = job_tree.create_item()
	
	var sorted_jobs := []
	if _filter != "":
		for j in buffered_jobs.keys():
			if _filter in j:
				sorted_jobs.append(j)
	else:
		sorted_jobs = buffered_jobs.keys()
	sorted_jobs.sort()
	
	for job_id in sorted_jobs:
		var new_job_tree_item : TreeItem = job_tree.create_item(job_tree_root)
		new_job_tree_item.set_text(0, job_id)
		


func _on_JobListTree_item_selected():
	show_job(job_tree.get_selected().get_text(0))


func show_job(job_id:String):
	for c in $"%JobView".get_children():
		c.queue_free()
	var new_job = JobElement.instance()
	$"%JobView".add_child(new_job)
	new_job.connect("delete_job", self, "_on_delete_job")
	new_job.connect("duplicate_job", self, "_on_duplicate_job")
	new_job.connect("cron_editor", self, "_on_cron_editor_open")
	new_job.setup(buffered_jobs[job_id])


func _on_cron_editor_open(_field_rect:Rect2, _expression:String, expr_field:Node) -> void:
	$"%CronHelper".popup(_expression, _field_rect.position, expr_field)


func _on_delete_job(job:Node) -> void:
	buffered_jobs.erase(job)
	job.queue_free()


var duplicate_data := {}
func _on_duplicate_job(job_id:String, copy_trigger_string:String, copy_job_command:String) -> void:
	duplicate_data = {"job_id" : job_id, "trigger_string" : copy_trigger_string, "job_command" : copy_job_command}
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Duplicate Job id",
		"Enter a new id for the duplicate of job. Do not use space:\n`%s`" % job_id,
		job_id+"-duplicate",
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_duplicate_confirm_response", [], CONNECT_ONESHOT)


func _on_duplicate_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		_value = _value.replace(" ", "-")
		# Check if a job with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		for job in buffered_jobs:
			if job.job_id == _value:
				_g.emit_signal("add_toast", "Duplication failed", "A Job with that name already exists.", 1, self)
				return
		latest_added_job_id = _value
		API.cli_execute("jobs add --id %s %s '%s'" % [_value, duplicate_data.trigger_string, duplicate_data.job_command], self, "_on_job_duplicate_done")
		duplicate_data.clear()


func _on_job_duplicate_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in duplicating Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	update_view()


func _on_AddJobButton_pressed():
	template_popup.popup(Rect2($"%AddJobButton".rect_global_position + Vector2($"%AddJobButton".rect_size.x+10, 0), Vector2.ONE))


func _on_add_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		_value = _value.replace(" ", "-")
		# Check if a job with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		for job in buffered_jobs:
			if job.job_id == _value:
				_g.emit_signal("add_toast", "Creation failed", "A Job with that name already exists.", 1, self)
				return
		latest_added_job_id = _value
		API.cli_execute("jobs add --id %s --schedule \"* * * * *\" 'echo hello world'" % _value, self, "_on_job_add_done")


func _on_job_add_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in adding Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	API.cli_execute("jobs deactivate %s" % latest_added_job_id, self, "_on_new_job_deactivate_done")
	latest_added_job_id = ""


func _on_new_job_deactivate_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in duplicating Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	update_view()


func _on_CronHelper_finished(_expression:String, _target_node:Node):
	_target_node.text = _expression
	if _target_node.text != _target_node.owner.job_schedule:
		_target_node.owner.show_save_options()


func _on_AddEmptyButton_pressed():
	template_popup.hide()
	var add_confirm_popup = _g.popup_manager.show_input_popup(
		"Add Job",
		"Enter a new id (name-for-job) for the job. Do not use space.",
		"new-job-" + str(OS.get_unix_time()),
		"Create Job", "Cancel")
	add_confirm_popup.connect("response_with_input", self, "_on_add_confirm_response", [], CONNECT_ONESHOT)


func _on_JobsComponent_show_section(is_visible:bool):
	if is_visible:
		update_view()


func _on_JobsListFilterLineEdit_text_changed(_new_text):
	update_navigation(_new_text)


func _on_SaveButton_pressed():
	var current_job : Node = null
	for c in $"%JobView".get_children():
		current_job = c
		break
	
	var params : Array = current_job.save_field()
	API.cli_execute("jobs update --id %s %s '%s'" % [params[0], params[1], params[2]], self, "_on_job_update_done")
	Analytics.event(Analytics.EventsJobEditor.SAVE)


func _on_DiscardButton_pressed():
	var current_job : Node = null
	for c in $"%JobView".get_children():
		current_job = c
		break
	current_job.restore_from_core()
