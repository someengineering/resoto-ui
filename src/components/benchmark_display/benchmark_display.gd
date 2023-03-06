extends MarginContainer

var benchmark_tree_root : CustomTreeItem = null
var tree_item_scene := preload("res://components/shared/custom_tree_item.tscn")
var check_collection_scene := preload("res://components/benchmark_display/benchmark_check_collection_display.tscn")
var check_result_scene := preload("res://components/benchmark_display/benchmark_check_result_display.tscn")
var check_account_scene := preload("res://components/benchmark_display/benchmark_account_display.tscn")

var last_detect_type := "manual"
var last_detect_command := ""

var sections := []

var checks := {}
var current_account : String = ""

var selected_element : CustomTreeItem = null

var benchmarks := {}
var benchmarks_count := 0

var benchmark_model : CustomTreeItem = null

var current_failing_resources : Array = []

onready var tree_container := $"%TreeContainer"

onready var passed_indicator := $"%PassingIndicator"
onready var failed_indicator := $"%FailingIndicator"

onready var detail_view := $"%DetailView"
onready var detail_view_title := $"%TitleLabel"
onready var detail_view_description := $"%DescriptionLabel"
onready var detail_view_pass_widget := $"%FailingVsPassingWidget"
onready var detail_remediation_label := $"%RemediationLabel"
onready var detail_risk_label := $"%RiskLabel"
onready var resources_list := $"%ResourcesList"
onready var resources_loading_overlay := $"%LoadingOverlay"
onready var benchmark_config_dialog := $"%BenchmarkConfigDialog"
onready var severity_indicator := $"%SeverityIndicator"
onready var result_count_panel := $"%ResultCountPanel"
onready var result_count_label := $"%ResultCountLabel"
onready var result_count_icon := $"%FailOrPassIcon"
onready var resource_count_label := $"%ResourcesCountTitle"
onready var risk_severity_label := $"%RiskSeverity"
onready var resources_container := $"%ResourcesContainer"
onready var remediation_button := $"%RemediationButton"
onready var detail_container := $"%VBoxContainer"
onready var checks_table_container := $"%ChecksTableContainer"
onready var checks_table_content := $"%ChecksTableContent"
onready var benchmark_label := $"%BenchmarkLabel"
onready var export_report_button := $"%ExportReportButton"

func _ready():
	detail_container.hide()
	export_report_button.hide()

func _on_get_configs_done(error: int, response):
	if error:
		# TODO handle error
		return
	benchmarks_count = 0
	
	for config in response.transformed.result:
		if config.begins_with("resoto.report.benchmark."):
			API.get_config_id(self, config)
			benchmarks_count += 1


func _on_get_benchmark_report_done(_error: int, response : ResotoAPI.Response):
	if _error:
		return
	
	var data : Array = response.transformed.result
	
	for item in data:
		if "kind" in item and item.kind == "report_check_result":
			
			for id in checks:
				var d = checks[id]
				var element = d[item.reported.id].main_element
				element.set_reported_data(item.reported)
				element.account_id = id
			
			if not "number_of_resources_failing_by_account" in item.reported:
				for d in checks.values():
					d[item.reported.id].main_element.failing_n = 0
			else:
				for a in checks:
					var tree_item : CustomTreeItem = checks[a][item.reported.id]
					if a in item.reported.number_of_resources_failing_by_account:
						tree_item.main_element.failing_n = item.reported.number_of_resources_failing_by_account[a]
					else:
						tree_item.main_element.failing_n = 0
						
	for check in checks.values():
		for item in check.values():
			var parent = item.parent
			while parent != null:
				if item.main_element.passed:
					parent.main_element.passing_n += 1
				else:
					parent.main_element.failing_n += 1
				parent = parent.parent
				
	passed_indicator.text = str(benchmark_tree_root.main_element.passing_n) + " Checks Passed"
	failed_indicator.text = str(benchmark_tree_root.main_element.failing_n) + " Checks Failed"
	failed_indicator.visible = benchmark_tree_root.main_element.failing_n > 0
	export_report_button.show()
	
	if selected_element != null and is_instance_valid(selected_element):
		_on_tree_item_pressed(selected_element)

func _on_tree_item_pressed(item : CustomTreeItem):
	detail_container.show()
	selected_element = item
	var element = item.main_element
	detail_view_title.raw_text = element.title
	
	if element.passed:
		result_count_label.text = "Passed!"		
		result_count_label.modulate = Color(0x004d4dff)
		result_count_panel.self_modulate =  Style.col_map[Style.c.CHECK_ON]
		result_count_icon.texture = preload("res://assets/icons/icon_128_check.svg")
		result_count_icon.modulate = Color(0x004d4dff)
		resource_count_label.visible = false
	else:
		result_count_icon.texture = preload("res://assets/icons/icon_128_close_thin.svg")
		result_count_icon.modulate = Color.white
		result_count_label.text = str(element.failing_n)
		result_count_label.modulate = Color.white
		resource_count_label.visible = true
		resource_count_label.text = str(element.failing_n)
		result_count_panel.self_modulate =  Style.col_map[Style.c.CHECK_FAIL]
	detail_view_pass_widget.visible = "passing_n" in element
	
	$"%RemediationContainer".visible = "remediation_text" in element
	$"%RiskContainer".visible = "risk" in element
	
	resources_container.visible = element is BenchmarkResultDisplay
	detail_view_description.visible = "description" in element
	
	detail_remediation_label.text = ""
	if "remediation_text" in element:
		detail_remediation_label.text = element.remediation_text
		if remediation_button.is_connected("pressed", OS, "shell_open"):
			remediation_button.disconnect("pressed", OS, "shell_open")
		if element.remediation_url != "":
			remediation_button.connect("pressed", OS, "shell_open", [element.remediation_url])
		remediation_button.visible = element.remediation_url != ""
		
			
	if "risk" in element:
		detail_risk_label.text = element.risk
	
	if "description" in element:
		detail_view_description.text = element.description
	
	if "passing_n" in element:
		detail_view_pass_widget.passing_n = element.passing_n
		detail_view_pass_widget.failing_n = element.failing_n
	
	if "severity" in element:
		severity_indicator.severity = element.severity
		risk_severity_label.text = "(%s)" % element.severity.capitalize()
		risk_severity_label.set("custom_colors/font_color", severity_indicator.severity_colors[element.severity])
		
	severity_indicator.visible = "severity" in element
	
	
	current_failing_resources = []
	if element is BenchmarkResultDisplay and not element.passed:
		API.get_check_resources(element.id, element.account_id, self)
		resources_container.visible = true
		resources_loading_overlay.visible = true
		checks_table_container.visible = false
	else:
		for row in checks_table_content.get_children():
			checks_table_content.remove_child(row)
			row.queue_free()
			
		var elements : Array = look_for_checks(selected_element)
		var data_elements : Array = []
		for check in elements:
			if check.failing_n == 0:
				continue
			if not check.title in data_elements:
				var table_element := preload("res://components/benchmark_display/checks_table_element.tscn").instance()
				table_element.check_name = check.title
				table_element.severity = check.severity
				table_element.failing_n = check.failing_n
				table_element.categories = check.categories
				checks_table_content.add_child(table_element)
				data_elements.append(check.title)
			else:
				var element_index := data_elements.find(check.title)
				checks_table_content.get_child(element_index).failing_n += check.failing_n
		
		checks_table_container.visible = true if checks_table_content.get_child_count() > 0 else false
		resources_container.visible = false


func _on_get_check_resources_done(error : int, response : ResotoAPI.Response):
	resources_loading_overlay.visible = false
	if error != OK:
		# TODO: manage errors
		return
	current_failing_resources = response.transformed.result
	populate_resources_list(response.transformed.result)
		
func populate_resources_list(request_result : Array):
	for resource in resources_list.get_children():
		resources_list.remove_child(resource)
		resource.queue_free()
	
	for resource in request_result:
		var template = preload("res://components/fulltext_search_menu/full_text_search_result_template.tscn").instance()
		template.get_node("VBox/Top/ResultKind").text = resource.reported.kind
		var id : String = resource.reported.id
		var resource_name : String = resource.reported.name
		
		template.get_node("VBox/Top/ResultName").text = resource_name if id == resource_name else "%s (%s)" % [resource_name, id]
		
		var cloud : String = resource.ancestors.cloud.reported.name if "cloud" in resource.ancestors else ""
		var region : String = resource.ancestors.region.reported.name if "region" in resource.ancestors else ""
		var account : String = resource.ancestors.account.reported.name if "account" in resource.ancestors else ""
		
		template.get_node("VBox/ResultDetails").text = "%s > %s > %s" % [cloud, account, region]
		resources_list.add_child(template)
		
		template.connect("pressed", self, "_on_resource_button_pressed", [resource.id])


func _on_resource_button_pressed(id : String):
	_g.content_manager.change_section_explore("node_single_info")
	_g.content_manager.find_node("NodeSingleInfo").show_node(id)

func _on_ShowAllButton_pressed():
	if not current_failing_resources.empty():
		_g.content_manager.change_section_explore("node_list_info")
		_g.content_manager.find_node("NodeListElement").show_resources_from_report_check(selected_element.main_element.id, selected_element.main_element.account_id)


func _on_Filter_option_changed(option):
	for section in sections:
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
	for section in sections:
		section.collapse(true)
		
	benchmark_tree_root.collapse(true)


func _on_Expand_pressed():
	for section in sections:
		section.collapse(false)
		
	benchmark_tree_root.collapse(false)


func _on_BenchmarkButton_pressed():
	$Control/BenchmarkConfigPopup.popup_centered()


func _on_AcceptButton_pressed():
	$Control/BenchmarkConfigPopup.hide()
	export_report_button.hide()
	detail_container.hide()
	selected_element = null
	create_benchmark_model(benchmark_config_dialog.selected_benchmark)
	benchmark_label.text = benchmark_config_dialog.selected_benchmark.title


func create_benchmark_model(data : Dictionary):
	for child in tree_container.get_children():
		if child is CustomTreeItem:
			tree_container.remove_child(child)
			child.queue_free()
	
	sections = []
	
	benchmark_tree_root = tree_item_scene.instance()
	benchmark_tree_root.main_element = new_check_collection_tree_item(data)
	benchmark_tree_root.main_element.set_label_variation("Label_24")
	benchmark_tree_root.main_element.set_collection_icon(BenchmarkCollectionDisplay.TYPES.BENCHMARK)
	
	benchmark_tree_root.connect("pressed", self, "_on_tree_item_pressed")
	tree_container.add_child(benchmark_tree_root)
	
	var accounts : Array = benchmark_config_dialog.accounts_checklist.checked_options
	
	checks = {}
	
	var accounts_id : Array = []
	for account in accounts:
		current_account = account.id
		accounts_id.append(account.id)
		var element = new_account_tree_item(account)
		element.set_label_variation("LabelBold")
		var tree_item = benchmark_tree_root.add_sub_element(element)
		tree_item.connect("pressed", self, "_on_tree_item_pressed")
		populate_tree_branch(data, tree_item)
	
	API.get_benchmark_report(data.id, PoolStringArray(accounts_id), self)
	
	benchmark_tree_root.collapse(false)


func populate_tree_branch(data : Dictionary, root : CustomTreeItem):
	sections.append(root)
	if "children" in data:
		for child in data.children:
			var element = new_check_collection_tree_item(child)
			element.set_collection_icon(BenchmarkCollectionDisplay.TYPES.COLLECTION)
			var item : CustomTreeItem = root.add_sub_element(element)
			item.connect("pressed", self, "_on_tree_item_pressed")
			populate_tree_branch(child, item)
	if "checks" in data:
		for check in data.checks:
			var element = new_check_result_tree_item(check)
			if not current_account in checks:
				checks[current_account] = {}
			var item : CustomTreeItem = root.add_sub_element(element)
			checks[current_account][check] = item
			item.connect("pressed", self, "_on_tree_item_pressed")
			sections.append(item)

func new_check_collection_tree_item(data):
	var element = check_collection_scene.instance()
	element.title = data.title
	element.description = data.description
	return element

func new_check_result_tree_item(id : String = ""):
	var element = check_result_scene.instance()
	element.id = id
	return element

func new_account_tree_item(account):
	var element = check_account_scene.instance()
	element.title = account.text
	element.name = account.name
	element.id = account.id
	return element


func look_for_checks(root : CustomTreeItem) -> Array:
	var elements : Array = []
	for element in root.sub_element_container.get_children():
		if element.main_element is BenchmarkResultDisplay:
			elements.append(element.main_element)
		else:
			elements.append_array(look_for_checks(element))
			
	return elements


func _on_ExportButton_pressed():
	var data : PoolStringArray = ["Severity", "Number of Resources Failing", "Check Name", "Categories"]
	var severities := ["low", "medium", "high", "critical"]
	for row in checks_table_content.get_children():
		var row_data : PoolStringArray = []
		var severity : String = row.severity
		severity = "%d - %s" % [severities.find(severity), severity]
		row_data.append(severity)
		row_data.append(str(row.failing_n))
		row_data.append(row.check_name)
		row_data.append(row.categories.join(" "))
		data.append(row_data.join(","))
	
	JavaScript.download_buffer(data.join("\n").to_utf8(), "Checks Report - %s.csv" % Time.get_datetime_string_from_system())



func _on_ExportReportButton_pressed():
	var checks := look_for_checks(benchmark_tree_root)
	var data : PoolStringArray = ["Severity", "Number of Resources Failing", "Check Name", "Categories", "Account ID"]
	var severities := ["low", "medium", "high", "critical"]
	for check in checks:
		var row_data : PoolStringArray = []
		var severity : String = check.severity
		severity = "%d - %s" % [severities.find(severity), severity]
		row_data.append(severity)
		row_data.append(str(check.failing_n))
		row_data.append(check.title)
		row_data.append((check.categories as PoolStringArray).join(" "))
		row_data.append(check.account_id)
		data.append(row_data.join(","))
	JavaScript.download_buffer(data.join("\n").to_utf8(), "Checks Report - %s.csv" % Time.get_datetime_string_from_system())
