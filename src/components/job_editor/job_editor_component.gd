extends Control

const JobElement = preload("res://components/job_editor/job_editor_element.tscn")
const NewJob : Dictionary = {
	"active" : true,
	"command" : "",
	"id" : "",
	"trigger" : { "cron_expression" : "* * * * *" }
}

var displayed_jobs = []

onready var template_popup := $TemplatePopup


func _ready():
	update_view()


func _on_jobs_list_data(_e, _d):
	pass


func update_view():
	for c in $"%JobList".get_children():
		c.queue_free()
	displayed_jobs.clear()
	API.cli_execute_json("jobs list", self, "_on_jobs_list_data", "_on_jobs_list_done" )


func _on_jobs_list_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in Job List display", Utils.err_enum_to_string(_error), 1, self)
		return
	if _response.transformed.has("result"):
		displayed_jobs.clear()
		for job in _response.transformed.result:
			create_job_element(job)


func create_job_element(job:Dictionary) -> void:
	var new_job = JobElement.instance()
	$"%JobList".add_child(new_job)
	$"%JobList".move_child(new_job, 0)
	new_job.connect("delete_job", self, "_on_delete_job")
	new_job.connect("duplicate_job", self, "_on_duplicate_job")
	new_job.connect("cron_editor", self, "_on_cron_editor_open")
	new_job.setup(job)
	displayed_jobs.append(new_job)


func _on_cron_editor_open(_field_rect:Rect2, _expression:String, expr_field:Node) -> void:
	$"%CronHelper".popup(_expression, _field_rect.position, expr_field)


func _on_delete_job(job:Node) -> void:
	displayed_jobs.erase(job)
	job.queue_free()


var duplicate_data := {}
func _on_duplicate_job(job_id:String, copy_trigger_string:String, copy_job_command:String) -> void:
	duplicate_data = {"job_id" : job_id, "trigger_string" : copy_trigger_string, "job_command" : copy_job_command}
	var rename_confirm_popup = _g.popup_manager.show_input_popup(
		"Duplicate Job id",
		"Enter a new id for the duplicate of job:\n`%s`" % job_id,
		job_id+"-duplicate",
		"Accept", "Cancel")
	rename_confirm_popup.connect("response_with_input", self, "_on_duplicate_confirm_response", [], CONNECT_ONESHOT)


func _on_duplicate_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		# Check if a job with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		for job in displayed_jobs:
			if job.job_id == _value:
				_g.emit_signal("add_toast", "Duplication failed", "A Job with that name already exists.", 1, self)
				return
		API.cli_execute("jobs add --id %s %s '%s'" % [_value, duplicate_data.trigger_string, duplicate_data.job_command], self, "_on_job_duplicate_done")
		duplicate_data.clear()


func _on_job_duplicate_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in duplicating Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	update_view()


func _on_AddJobButton_pressed():
	template_popup.popup(Rect2($"%AddJobButton".rect_global_position + Vector2($"%AddJobButton".rect_size.x+10, 0), Vector2.ONE))
#	var add_confirm_popup = _g.popup_manager.show_input_popup(
#		"Add Job",
#		"Enter a new id (name) for the job",
#		"new-job-" + str(OS.get_unix_time()),
#		"Create Job", "Cancel")
#	add_confirm_popup.connect("response_with_input", self, "_on_add_confirm_response", [], CONNECT_ONESHOT)


func _on_add_confirm_response(_button_clicked:String, _value:String):
	if _button_clicked == "left":
		# Check if a job with that name already exsits.
		# To make sure no config was created while editing, check for new config keys:
		for job in displayed_jobs:
			if job.job_id == _value:
				_g.emit_signal("add_toast", "Duplication failed", "A Job with that name already exists.", 1, self)
				return
		API.cli_execute("jobs add --id %s --schedule \"* * * * *\" 'echo hello world'" % _value, self, "_on_job_add_done")


func _on_job_add_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in adding Job.", _response.body.get_string_from_utf8(), 1, self)
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
		"Enter a new id (name) for the job",
		"new-job-" + str(OS.get_unix_time()),
		"Create Job", "Cancel")
	add_confirm_popup.connect("response_with_input", self, "_on_add_confirm_response", [], CONNECT_ONESHOT)
