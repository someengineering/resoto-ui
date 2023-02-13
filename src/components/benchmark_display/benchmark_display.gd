extends MarginContainer

onready var combo_box := $PanelContainer/Content/HBoxContainer/ComboBox
onready var tree_container := $PanelContainer/Content/PanelContainer/TreeContainer

onready var passed_indicator := $PanelContainer/Content/PanelContainer2/HBoxContainer2/PassIndicator
onready var failed_indicator := $PanelContainer/Content/PanelContainer2/HBoxContainer2/FailIndicator

var benchmark_tree_root : CustomTreeItem = null
var tree_item_scene := preload("res://components/shared/custom_tree_item.tscn")

var sections := {}

func _on_BenchmarkDisplay_visibility_changed():
	API.get_configs(self)
	

func _on_get_configs_done(error: int, response):
	if error:
		# TODO handle error
		return
	var benchmarks := []
	
	for config in response.transformed.result:
		if config.begins_with("resoto.report.benchmark."):
			benchmarks.append(config.replace("resoto.report.benchmark.", ""))
	
	combo_box.items = benchmarks


func _on_get_benchmark_report_done(_error: int, response):
	if _error:
		# TODO handle error
		return
		
	sections = {}
	if benchmark_tree_root:
		benchmark_tree_root.queue_free()
	
	for element in response.transformed.result:
		if "kind" in element and element.kind == "report_check_result":
			if element.reported.remediation.action != null:
				pass
			var display_element = preload("res://components/benchmark_display/benchmark_check_result_display.tscn").instance()
			display_element.passed = element.reported.passed
			display_element.failing_n = element.reported.number_of_resources_failing
			display_element.title = element.reported.title
			
			display_element.remediation_text = element.reported.remediation.text
			display_element.remediation_url = element.reported.remediation.url
			
			display_element.severity = element.reported.severity
			
			var last_element_name = sections.keys()[-1]
			var item = sections[last_element_name].add_sub_element(display_element)
			sections[sections.keys()[-1] + "-" + element.reported.title] = item
			
		elif "reported" in element and "kind" in element.reported:
			var display_element := preload("res://components/benchmark_display/benchmark_check_collection_display.tscn").instance()
			var title : String = element.reported.title
			display_element.title = title
			display_element.passed = element.reported.passed
			display_element.passing_n = element.reported.checks_passing
			display_element.failing_n = element.reported.checks_failing
			display_element.tooltip = element.reported.description
			
			match element.reported.kind:
				"report_benchmark":
					display_element.set_label_variation("Label_24")
					benchmark_tree_root = tree_item_scene.instance()
					benchmark_tree_root.main_element = display_element
					tree_container.add_child(benchmark_tree_root)
				"report_check_collection":
					if title.begins_with("Section"):
						display_element.set_label_variation("LabelBold")
						var section = title.split(":")[0].split(" ")[1]
						var item = benchmark_tree_root.add_sub_element(display_element)
						sections[section] = item
					else:
						var section_numbers : String = title.split(" ")[0]
						var section_index = section_numbers
						var index = -1
						while true:
							index = section_numbers.rfind(".", index)
							section_numbers = section_numbers.left(index)
							if section_numbers in sections:
								var item = sections[section_numbers].add_sub_element(display_element)
								sections[section_index] = item
								break
	
	passed_indicator.value = benchmark_tree_root.main_element.passing_n
	failed_indicator.value = benchmark_tree_root.main_element.failing_n
	benchmark_tree_root.collapse(false)

func _on_ComboBox_option_changed(option):
	
	API.get_benchmark_report(option, self)


func _on_Filter_option_changed(option):
	for section in sections.values():
		match option:
			"All":
				section.visible = true
			"Passing":
				section.visible = section.main_element.passed
				if section.visible:
					section.collapse(false)
					while section.parent != benchmark_tree_root:
						section.parent.visible = true
						section = section.parent
						section.collapse(false)
			"Failing":
				section.visible = not section.main_element.passed
				if section.visible:
					section.collapse(false)


func _on_Collapse_pressed():
	for section in sections.values():
		section.collapse(true)
		
	benchmark_tree_root.collapse(true)


func _on_Expand_pressed():
	for section in sections.values():
		section.collapse(false)
		
	benchmark_tree_root.collapse(false)
