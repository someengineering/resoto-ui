extends Control

const ToggleTexOn : Texture = preload("res://assets/icons/icon_128_toggle_on.svg")
const ToggleTexOff : Texture = preload("res://assets/icons/icon_128_toggle_off.svg")
const JobElement : PackedScene = preload("res://components/job_editor/job_editor_element.tscn")
const NewJob : Dictionary = {
	"active" : true,
	"command" : "",
	"id" : "new-job-id",
	"trigger" : { "cron_expression" : "0 * * * *" },
	"is_new_job" : true
}

var buffered_jobs := []
var latest_added_job_id := ""
var job_tree_root : TreeItem = null

onready var job_tree := $"%JobListTree"


func _on_jobs_list_data(_e, _d):
	pass


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
	buffered_jobs.append(job)
	update_navigation()


func get_job_ids_from_array(job_array:Array) -> Array:
	var id_array := []
	for j in job_array:
		id_array.append(j.id)
	return id_array


func get_array_index_from_job_id(job_id:String) -> int:
	for i in buffered_jobs.size():
		if buffered_jobs[i].id == job_id:
			return i
	return -1


func update_navigation(_filter:=""):
	job_tree.clear()
	job_tree.set_column_expand(0, true)
	job_tree.set_column_expand(1, false)
	job_tree.set_column_min_width(1, 40)
	job_tree_root = job_tree.create_item()
	
	var sorted_jobs := []
	var job_ids : Array = get_job_ids_from_array(buffered_jobs)
	if _filter != "":
		for j in job_ids:
			if _filter in j:
				sorted_jobs.append(j)
	else:
		sorted_jobs = job_ids
	sorted_jobs.sort()
	
	var current_job : Node = get_opened_job()
	
	for job_id in sorted_jobs:
		var new_job_tree_item : TreeItem = job_tree.create_item(job_tree_root)
		new_job_tree_item.set_text(0, job_id)
		var is_active = buffered_jobs[get_array_index_from_job_id(job_id)].active
		var activity_icon := ToggleTexOn if is_active else ToggleTexOff
		new_job_tree_item.set_icon(1, activity_icon)
		new_job_tree_item.set_icon_max_width(1, 20)
		if is_active:
			new_job_tree_item.set_icon_modulate(1, Style.col_map[Style.c.LIGHT])
		else:
			new_job_tree_item.set_icon_modulate(1, Style.col_map[Style.c.DARK].lightened(0.3))
			new_job_tree_item.set_custom_color(0, Style.col_map[Style.c.DARK].lightened(0.3))
		# If a job is already open, select the element
		if current_job != null and current_job.job_id == job_id:
			new_job_tree_item.select(0)


func _on_JobListTree_item_selected():
	if job_tree_root.is_selected(0):
		return
	var job_index : int = get_array_index_from_job_id(job_tree.get_selected().get_text(0))
	if job_index == -1:
		_g.emit_signal("add_toast", "Job not found", "A job with the id '%s' could not be found." % job_tree.get_selected().get_text(0), 1, self)
		return
	show_job(buffered_jobs[job_index])


func show_job(job:Dictionary):
	$"%SaveDiscardBar".hide()
	for c in $"%JobView".get_children():
		c.queue_free()
	var new_job = JobElement.instance()
	$"%JobView".add_child(new_job)
	new_job.connect("delete_job", self, "_on_delete_job")
	new_job.connect("changed_active_state", self, "update_activity_state")
	new_job.connect("duplicate_job", self, "_on_duplicate_job")
	new_job.connect("show_save_options", self, "_on_show_save_options")
	new_job.connect("cron_editor", self, "_on_cron_editor_open")
	new_job.setup(job)


func _on_cron_editor_open(_field_rect:Rect2, _expression:String, expr_field:Node) -> void:
	$"%CronHelper".popup(_expression, _field_rect.position, expr_field)


func update_activity_state(_job_id:String, _job_is_active:bool):
	buffered_jobs[get_array_index_from_job_id(_job_id)].active = _job_is_active
	update_navigation($"%JobsListFilterLineEdit".text)


func _on_delete_job(job:Node) -> void:
	buffered_jobs.remove(get_array_index_from_job_id(job.job_id))
	job.queue_free()
	update_navigation($"%JobsListFilterLineEdit".text)
	$"%SaveDiscardBar".hide()


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
		Analytics.event(Analytics.EventsJobEditor.DUPLICATE)
		API.cli_execute("jobs add --id %s %s '%s'" % [_value, duplicate_data.trigger_string, duplicate_data.job_command], self, "_on_job_duplicate_done")
		duplicate_data.clear()


func _on_job_duplicate_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in duplicating Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	update_view()


func _on_AddJobButton_pressed():
	show_job(NewJob.duplicate(true))
	_on_show_save_options(true)
	job_tree_root.select(0)


func _on_job_add_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in adding Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	API.cli_execute("jobs deactivate %s" % latest_added_job_id, self, "_on_new_job_deactivate_done")
	latest_added_job_id = ""
	# Free the "new job" preview
	var current_job : Node = null
	for c in $"%JobView".get_children():
		current_job = c
		break
	if current_job.job_is_new:
		current_job.queue_free()
	$"%SaveDiscardBar".hide()


func _on_new_job_deactivate_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in duplicating Job.", _response.body.get_string_from_utf8(), 1, self)
		return
	update_view()


func _on_CronHelper_finished(_expression:String, _target_node:Node):
	_target_node.text = _expression
	if _target_node.text != _target_node.owner.job_schedule:
		_target_node.owner.show_save_options()


func _on_JobsComponent_show_section(is_visible:bool):
	if is_visible:
		update_view()


func _on_JobsListFilterLineEdit_text_changed(_new_text):
	update_navigation(_new_text)


func _on_show_save_options(is_new_job:=false):
	if is_new_job:
		$"%SaveButton".text = "Add new Job"
		$"%DiscardButton".text = "Discard new Job"
	else:
		$"%SaveButton".text = "Save Changes"
		$"%DiscardButton".text = "Discard Changes"
	$"%SaveDiscardBar".show()


func _on_SaveButton_pressed():
	var current_job : Node = null
	for c in $"%JobView".get_children():
		current_job = c
		break
	
	var params : Array = current_job.save_field()
	if current_job.job_is_new:
		API.cli_execute("jobs add --id %s %s '%s'" % [params[0], params[1], params[2]], self, "_on_job_add_done")
	else:
		API.cli_execute("jobs update --id %s %s '%s'" % [params[0], params[1], params[2]], self, "_on_job_update_done")
	Analytics.event(Analytics.EventsJobEditor.SAVE)


func _on_job_update_done(_error:int, _response:UserAgent.Response) -> void:
	if _error:
		_g.emit_signal("add_toast", "Error in Job update", _response.body.get_string_from_utf8(), 1, self)
		return
	$"%SaveDiscardBar".hide()


func _on_DiscardButton_pressed():
	var current_job : Node = get_opened_job()
	if current_job.job_is_new:
		current_job.queue_free()
	else:
		current_job.restore_from_core()
	$"%SaveDiscardBar".hide()


func get_opened_job() -> Node:
	var current_job : Node = null
	for c in $"%JobView".get_children():
		current_job = c
		break
	return current_job
