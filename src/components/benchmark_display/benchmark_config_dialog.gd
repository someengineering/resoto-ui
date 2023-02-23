extends MarginContainer

var benchmarks_count := 0
var benchmarks := {}

onready var clouds_checklist := $VBoxContainer/CloudsCheckList
onready var accounts_checklist := $VBoxContainer/AccountsCheckList
onready var combo_box := $VBoxContainer/HBoxContainer/ComboBox


func _on_get_configs_done(error: int, response):
	if error:
		# TODO handle error
		return
	benchmarks_count = 0
	
	for config in response.transformed.result:
		if config.begins_with("resoto.report.benchmark."):
			API.get_config_id(self, config)
			benchmarks_count += 1
			

func _on_get_config_id_done(error: int, response : ResotoAPI.Response, config_id : String):
	if error != OK:
		# TODO handle errors
		return
		
	var benchmark : Dictionary = response.transformed.result.report_benchmark
	benchmarks[benchmark.id] = benchmark
	
	benchmarks_count -=  1
	if benchmarks_count <= 0:
		combo_box.items = benchmarks.keys()


func _on_benchmark_config_dialog_visibility_changed():
	if is_visible_in_tree():
		API.get_configs(self)


func _on_ComboBox_option_changed(option):
	if "clouds" in benchmarks[option]:
		clouds_checklist.items = benchmarks[option]["clouds"]


func _on_CloudsCheckList_selection_changed(selected_items : Array):
	API.graph_search("is(account) and /ancestors.cloud.reported.name in %s" % var2str(selected_items), self)


func _on_graph_search_done(error : int, response : ResotoAPI.Response):
	if error != OK:
		# TODO handle error
		return
		
	var accounts : Array = response.transformed.result
	var accounts_id : Array = []
	
	for account in accounts:
		accounts_id.append(account.reported.id)
		
	accounts_checklist.items = accounts_id
