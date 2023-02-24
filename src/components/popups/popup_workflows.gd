extends PanelContainer

export (NodePath) var status_icon_path : NodePath = ""

var status_icon : Node = null

onready var workflow_display := $Margin/VBox/CollectRunDisplay


func _ready():
	workflow_display.update_title_text("No active workflow")
	rect_size.y = 1
	status_icon = get_node_or_null(status_icon_path)
	update_running_workflows()


func update_running_workflows():
	API.cli_execute_json("workflow running", self, "_on_get_running_workflows_data", "_on_get_running_workflows_done")


func _on_get_running_workflows_data(_e, _r):
	pass


func _on_get_running_workflows_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		return
	for workflow in _response.transformed.result:
		if workflow.progress != "done":
			workflow_display.update_title_text(workflow.workflow)
			workflow_started(false)
			return
	workflow_display.update_title_text("No active workflow")


var is_running_workflow := false
func workflow_started(do_update:=true):
	if is_running_workflow:
		return
	is_running_workflow = true
	if do_update:
		update_running_workflows()
	if status_icon:
		status_icon.get_node("Error").hide()
		status_icon.get_node("Progressing").show()


# workflow is done
func _on_CollectRunDisplay_all_done(_without_errors:bool):
	is_running_workflow = false
	if status_icon:
		status_icon.get_node("Error").visible = not _without_errors
		status_icon.get_node("Progressing").hide()


func _on_HideWorkflowStatusTween_tween_all_completed():
	rect_size.y = 1


func _on_CollectRunDisplay_message_new():
	workflow_started()
