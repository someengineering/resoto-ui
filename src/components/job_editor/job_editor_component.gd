extends Control

const JobElement = preload("res://components/job_editor/job_editor_element.tscn")

var displayed_jobs = []


func _ready():
	API.cli_execute_json("jobs list", self, "_on_jobs_list_data", "_on_jobs_list_done" )


func _on_jobs_list_data(_e, _d):
	pass


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
	$JobsPanel/JobList.add_child(new_job)
	new_job.setup(job)
	displayed_jobs.append(new_job)
