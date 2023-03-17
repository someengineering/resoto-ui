extends MarginContainer

var benchmarks_count := 0
var benchmarks := {}
var selected_benchmark : Dictionary = {}

onready var clouds_checklist := $"%CloudsCheckList"
onready var accounts_checklist := $"%AccountsCheckList"
onready var combo_box := $"%BenchmarkComboBox"


func _ready():
	update_view()

func update_view():
	show_benchmark_help(combo_box.text == "")


func _on_get_configs_done(error: int, response):
	if error:
		# TODO handle error
		return
	benchmarks_count = 0
	
	for config in response.transformed.result:
		if config.begins_with("resoto.report.benchmark."):
			API.get_config_id(self, config)
			benchmarks_count += 1
			

func _on_get_config_id_done(error: int, response : ResotoAPI.Response, _config_id : String):
	if error != OK:
		# TODO handle errors
		return
		
	var benchmark : Dictionary = response.transformed.result.report_benchmark
	benchmarks[benchmark.title] = benchmark
	
	benchmarks_count -=  1
	if benchmarks_count <= 0:
		combo_box.items = benchmarks.keys()


func _on_benchmark_config_dialog_visibility_changed():
	if is_visible_in_tree():
		API.get_configs(self)


func _on_ComboBox_option_changed(option):
	show_benchmark_help(option == "")
		
	if "clouds" in benchmarks[option]:
		clouds_checklist.items = benchmarks[option]["clouds"]
	selected_benchmark = benchmarks[option]
	clouds_checklist.select_all()


func show_benchmark_help(_show:bool):
	$"%BenchmarkMissingHintHighlight".visible = _show
	$"%BenchmarkMissingHint".visible = _show
	accounts_checklist.visible = not _show
	clouds_checklist.visible = not _show


func _on_CloudsCheckList_selection_changed(selected_items : Array):
	API.graph_search("is(account) and /ancestors.cloud.reported.name in %s" % var2str(selected_items), self)


func _on_graph_search_done(error : int, response : ResotoAPI.Response):
	if error != OK:
		# TODO handle error
		return
		
	var accounts : Array = response.transformed.result
	var accounts_id : Array = []

	for account in accounts:
		var n = account.reported.name
		var id = account.reported.id
		accounts_id.append({
			"text" : n if n == id else "%s (%s)" % [n, id],
			"name" : n,
			"id" : id
			})
	
	accounts_id.sort_custom(self, "sort_by_name")
	accounts_checklist.items = accounts_id
	
	accounts_checklist.select_all()


func sort_by_name(a: Dictionary, b: Dictionary):
	if a.name < b.name:
		return true
	return false
