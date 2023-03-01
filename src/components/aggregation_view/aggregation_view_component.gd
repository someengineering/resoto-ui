extends Control

var aggregation_example : Array = [
	{
		"query" : "aggregate(/ancestors.cloud.reported.name as cloud, /ancestors.account.reported.name as account, /ancestors.region.reported.name as region, instance_type as type : sum(1) as instances_total, sum(instance_cores) as cores_total, sum(instance_memory*1024*1024*1024) as memory_bytes): is(instance)",
		"descr" : "Aggregate Instances by Region and Instance Type, show their count, total cores, and memory."
	},
	{
		"query" : "aggregate(/ancestors.cloud.reported.name as cloud, /ancestors.account.reported.name as account, /ancestors.region.reported.name as region, instance_type as type : sum(/ancestors.instance_type.reported.ondemand_cost) as instances_hourly_cost_estimate): is(instance) and instance_status = running",
		"descr" : "Aggregate running Instances, show their on demand cost."
	}
]

var active_aggregate_request : ResotoAPI.Request
var active_result : Array = []

onready var edit : TextEdit = $"%TextEdit"
onready var delay_timer : Timer = $"%ExecuteDelayTimer"
onready var template_popup := $TemplatePopup


func _ready():
	_g.connect("aggregation_view_show", self, "show_aggregation")
	add_templates()


func add_templates():
	for example in aggregation_example:
		var new_button : Button = Button.new()
		new_button.text = example.descr
		new_button.align = Button.ALIGN_LEFT
		$"%TemplateContent".add_child(new_button)
		new_button.connect("pressed", self, "show_aggregation", [example.query])


func show_aggregation(_new_text:String):
	template_popup.hide()
	edit.text = _new_text
	$"%HintContainer".visible = edit.text == ""
	execute_aggregation()


func execute_aggregation():
	if active_aggregate_request:
		active_aggregate_request.cancel()
	$"%LoadingOverlay".show()
	active_aggregate_request = API.aggregate_search(edit.text, self)


func _on_ExecuteDelayTimer_timeout():
	execute_aggregation()


func _on_TextEdit_text_changed():
	$"%HintContainer".visible = edit.text == ""
	delay_timer.start()


func _on_aggregate_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		show_result(false)
		if error == ERR_PRINTER_ON_FIRE:
			return
		$"%ErrorLabel".text = _response.body.get_string_from_utf8()
		$"%ErrorLabel".show()
		_g.emit_signal("add_toast", "Error in Search", "Query: "+ active_aggregate_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		active_result = _response.transformed.result
		$"%ResultTableWidget".set_data(_response.transformed.result, DataSource.TYPES.AGGREGATE_SEARCH)
		show_result(true)


func show_result(show:bool):
	$"%LoadingOverlay".hide()
	$"%ResultHeadline".visible = show
	$"%ResultTableWidget".visible = show
	if not show:
		$"%ResultTableWidget".clear_all()
	else:
		$"%ErrorLabel".hide()


func _on_CopyButton_pressed():
	_g.emit_signal("text_to_clipboard", edit.text)


func _on_CopyCSVButton_pressed():
	_g.emit_signal("text_to_clipboard", $"%ResultTableWidget".get_csv())


func _on_CopyJSONButton_pressed():
	_g.emit_signal("text_to_clipboard", active_result)


func _on_AddExample_pressed():
	template_popup.popup(Rect2($"%AddExample".rect_global_position + Vector2($"%AddExample".rect_size.x+10, 0), Vector2.ONE))


func _on_DocsButton_pressed():
	OS.shell_open("https://resoto.com/docs/reference/cli/search-commands/aggregate")
