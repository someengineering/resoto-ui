extends WizardStep

onready var results := $VBoxContainer/CollectRunDisplay/PanelContainer/Content/CollectResultTree

func _ready():
	results.connect("done_with_display", self, "_on_CollectRunResults_done")

func start(_data:Dictionary):
	emit_signal("can_previous", false)


func _on_CollectRunResults_done():
	emit_signal("can_continue")
