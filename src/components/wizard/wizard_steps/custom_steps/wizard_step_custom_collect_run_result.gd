extends WizardStep

onready var results := $VBoxContainer/CollectRunDisplay/PanelContainer/Content/CollectResultTree

func _ready():
	results.connect("done_with_display", self, "_on_CollectRunResults_done")


func start(_data:Dictionary):
	custom_buttons = []
	results.refresh_results()
	var connections : Array = wizard.data.connections_from[step_id]
	
	for node_id in connections:
		var node_data = wizard.get_step_data(node_id.to)
		if node_data.res_name == "StepButton":
			var node_connection = wizard.data.connections_from[str(node_data.id)][0]
			var button_data : Dictionary = {
				"text" : node_data.step_text,
				"to" : wizard.get_step_data(node_connection.to).id
			}
			custom_buttons.append(button_data)
	emit_signal("can_previous", false)


func _on_CollectRunResults_done():
	pass
#	emit_signal("can_continue")
