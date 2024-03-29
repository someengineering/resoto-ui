extends MarginContainer

signal expand_account_finished
signal all_accounts_expanded
signal all_collapsed

var benchmark_tree_root : CustomTreeItem = null
var tree_item_scene := preload("res://components/shared/custom_tree_item.tscn")
var check_collection_scene := preload("res://components/benchmark_display/benchmark_check_collection_display.tscn")
var check_result_scene := preload("res://components/benchmark_display/benchmark_check_result_display.tscn")
var check_account_scene := preload("res://components/benchmark_display/benchmark_account_display.tscn")

var last_detect_type := "manual"
var last_detect_command := ""

var checks := {}

var selected_element : CustomTreeItem = null

var benchmarks := {}
var benchmarks_count := 0
var accounts : Array = []
var current_account : String = ""
var collapsed_accounts : Array = []
var account_trees : Dictionary = {}
var current_expanded_account : CustomTreeItem = null

var severities := ["low", "medium", "high", "critical"]

var benchmark_model : CustomTreeItem = null

var current_failing_resources : Array = []

onready var tree_container := $"%TreeContainer"

onready var passed_indicator := $"%PassingIndicator"
onready var failed_indicator := $"%FailingIndicator"

var number_of_nodes := 0

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
onready var benchmark_button := $"%BenchmarkButton"
onready var expand_button := $"%Expand"
onready var collapse_button := $"%Collapse"
onready var filter_combo := $"%Filter"


func _ready():
	detail_container.hide()
	export_report_button.hide()
	check_help_view()


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
	set_top_buttons_disabled(false)
	
	if _error:
		print(response.body.get_string_from_utf8())
		return
	
	var data : Array = response.transformed.result
	checks = {}
	var total_passing := 0
	var total_failing := 0
	for item in data:
		if "kind" in item and item.kind == "report_check_result":
			checks[item.reported.id] = item.reported
			checks[item.reported.id]["failing_resources"] = {}
			
			if "number_of_resources_failing_by_account" in item.reported:
				var resources_by_account : Dictionary = item.reported.number_of_resources_failing_by_account
				checks[item.reported.id]["failing_resources"] = resources_by_account
				
				for account in benchmark_tree_root.sub_element_container.get_children():
					if account.name in resources_by_account:
						account.main_element.failing_n += 1
						total_failing += 1
					else:
						account.main_element.passing_n += 1
						total_passing += 1
					account.collapsable = true
			else:
				for account in benchmark_tree_root.sub_element_container.get_children():
					account.main_element.passing_n += 1
					total_passing += 1

	benchmark_tree_root.main_element.passing_n = total_passing
	benchmark_tree_root.main_element.failing_n = total_failing
	passed_indicator.text = str(total_passing) + " Checks Passed"
	failed_indicator.text = str(total_failing) + " Checks Failed"
	failed_indicator.visible = total_failing > 0
	export_report_button.show()
	
	if selected_element != null and is_instance_valid(selected_element):
		_on_tree_item_pressed(selected_element)
	

func _on_account_collapsed_changed(item : CustomTreeItem = null, data : Dictionary = {}):
	if item == null:
		return
	if item.collapse_button.pressed:
		current_expanded_account = item
		for account in benchmark_tree_root.sub_element_container.get_children():
			if account == item:
				continue
			if not account.main_element.account_id in account_trees and not account in collapsed_accounts:
				account_trees[account.main_element.account_id] = account.sub_element_container
				account.sub_container.remove_child(account.sub_element_container)
			account.collapse(true)
			
		if item in collapsed_accounts:
			collapsed_accounts.erase(item)
			current_account = item.name
			var branch_checks := populate_tree_branch(data, item)
			
			for check in branch_checks:
				var current_item = check
				while current_item.parent != item:
					if check.main_element.passed:
						current_item.parent.main_element.passing_n += 1
					else:
						current_item.parent.main_element.failing_n += 1
					current_item = current_item.parent
		elif item.sub_container.get_node_or_null("SubElements") == null:
			item.sub_container.add_child(account_trees[item.main_element.account_id])
		filter_all(item, filter_combo.text)
	elif current_expanded_account == item:
		current_expanded_account = null
		
	emit_signal("expand_account_finished")


func expand_account(account_item : CustomTreeItem):
	var function_state = account_item.collapse(false)
	if function_state is GDScriptFunctionState:
		yield(function_state, "completed")
	change_collapse_all(account_item, false)


func _on_tree_item_pressed(item : CustomTreeItem):
	detail_container.show()
	selected_element = item
	var element = item.main_element
	detail_view_title.raw_text = element.title
	
	if element.passed:
		result_count_label.text = "Passed!"
		result_count_label.modulate = Color(0x004d4dff)
		result_count_panel.self_modulate =  Style.col_map[Style.c.CHECK_ON]
		result_count_icon.visible = true
		resource_count_label.visible = false
	else:
		result_count_icon.visible = false
		var result_text : String = str(element.failing_n) + (" resources failing" if selected_element.main_element is BenchmarkResultDisplay else " checks failing")
		if element.failing_n == 1:
			result_text = result_text.replace("resources", "resource").replace("checks",  "check")
		result_count_label.text = result_text
		result_count_label.modulate = Color.white
		resource_count_label.visible = true
		resource_count_label.text = str(element.failing_n)
		$"%ResourcesTitle".text = "Failing Resource" if element.failing_n == 1 else "Failing Resources"
		result_count_panel.self_modulate =  Style.col_map[Style.c.CHECK_FAIL]
	detail_view_pass_widget.visible = "passing_n" in element
	
	resources_container.visible = element is BenchmarkResultDisplay
	detail_view_description.visible = "description" in element

	if "description" in element:
		detail_view_description.text = element.description
	
	if "passing_n" in element:
		detail_view_pass_widget.passing_n = element.passing_n
		detail_view_pass_widget.failing_n = element.failing_n
	
	current_failing_resources = []
	if element is BenchmarkResultDisplay:
		checks_table_container.visible = false
		if not element.passed:
			API.get_check_resources(element.id, element.account_id, self)
			resources_container.visible = true
			resources_loading_overlay.visible = true
			checks_table_container.visible = false
		else:
			resources_container.visible = false
			
		$"%RemediationContainer".visible = true
		$"%RiskContainer".visible = true
		severity_indicator.visible = true
		
		var check = checks[element.id]
		
		detail_remediation_label.text = check.remediation.text
		if remediation_button.is_connected("pressed", OS, "shell_open"):
			remediation_button.disconnect("pressed", OS, "shell_open")
		if check.remediation.url != "":
			remediation_button.connect("pressed", OS, "shell_open", [check.remediation.url])
			remediation_button.show()
		else:
			remediation_button.hide()
		remediation_button.visible = check.remediation.url != ""
		
		detail_risk_label.text = check.risk
		severity_indicator.severity = check.severity
		risk_severity_label.text = "(%s)" % check.severity.capitalize()
		risk_severity_label.set("custom_colors/font_color", severity_indicator.severity_colors[check.severity])
		
	else:
		$"%RemediationContainer".visible = false
		$"%RiskContainer".visible = false
		severity_indicator.visible = false
		
		for row in checks_table_content.get_children():
			checks_table_content.remove_child(row)
			row.queue_free()
		
		var title = selected_element.main_element.title if not selected_element.main_element is BenchmarkAccountDisplay else benchmark_tree_root.main_element.title
		var elements : Array = look_for_checks(title)
		var data_elements : Array = []
		var filter_account := get_element_account(selected_element)
		
		for check in elements:
			if filter_account != "" and not filter_account in check.failing_resources:
				continue
			if not check.title in data_elements:
				var table_element := preload("res://components/benchmark_display/checks_table_element.tscn").instance()
				table_element.check_name = check.title
				table_element.severity = check.severity
				for account_id in check.failing_resources:
					if filter_account == "" or account_id == filter_account:
						table_element.failing_n += check.failing_resources[account_id]
				if table_element.failing_n == 0:
					continue
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
	if benchmark_tree_root == null or current_expanded_account == null:
		return
		
	set_top_buttons_disabled(true)

	change_collapse_all(current_expanded_account, false, current_expanded_account)
	yield(self, "all_collapsed")
	
	filter_all(current_expanded_account, option)
	
	set_top_buttons_disabled(false)
	


func _on_Collapse_pressed():
	set_top_buttons_disabled(true)
	change_collapse_all(benchmark_tree_root, true)
	yield(self, "all_collapsed")
	set_top_buttons_disabled(false)


func _on_Expand_pressed():
	set_top_buttons_disabled(true)
	
	$ExpandAccountsTimer.start()
	yield(self, "all_accounts_expanded")
	
	change_collapse_all(benchmark_tree_root, false)
	yield(self, "all_collapsed")
	
	print(number_of_nodes)
	set_top_buttons_disabled(false)
	
	
func change_collapse_all(item : CustomTreeItem, collapse : bool, root : CustomTreeItem = benchmark_tree_root):
	item.collapse(collapse)
	for sub_element in item.sub_element_container.get_children():
		change_collapse_all(sub_element, collapse)
		yield(get_tree(), "idle_frame")
		
	if item == root:
		emit_signal("all_collapsed")


func filter_all(item : CustomTreeItem, condition : String):
	var v : bool
	match condition:
		"Failing":
			v = item.main_element.passed == false
		"Passing":
			if item.main_element is BenchmarkResultDisplay:
				v = item.main_element.passed
			else:
				v = item.main_element.passing_n > 0
		"All":
			v = true
			
	item.visible = v
	if v:
		for sub_element in item.sub_element_container.get_children():
			filter_all(sub_element, condition)


func _on_BenchmarkButton_pressed():
	$"%BenchmarkConfigPopup".popup_centered()
	$"%BenchmarkConfigDialog".update_view()


func _on_AcceptButton_pressed():
	$"%BenchmarkConfigPopup".hide()
	export_report_button.hide()
	detail_container.hide()
	selected_element = null
	create_benchmark_model(benchmark_config_dialog.selected_benchmark)
	benchmark_label.text = benchmark_config_dialog.selected_benchmark.title
	check_help_view()


func check_help_view():
	var show_help : bool = benchmark_config_dialog.selected_benchmark.empty()
	$"%BenchmarkMissingHintHighlight".visible = show_help
	$"%BenchmarkResultView".visible = not show_help
	$"%ExportReportButton".visible = not show_help


func _on_BenchmarkDisplay_visibility_changed():
	if visible:
		check_help_view()
		if benchmark_config_dialog.selected_benchmark.empty():
			_on_BenchmarkButton_pressed()
	else:
		$"%BenchmarkPopupBG".hide()


func create_benchmark_model(data : Dictionary):
	filter_combo.text = "All"
	for child in tree_container.get_children():
		if child is CustomTreeItem:
			tree_container.remove_child(child)
			child.queue_free()
	
	benchmark_tree_root = tree_item_scene.instance()
	benchmark_tree_root.main_element = new_check_collection_tree_item(data)
	benchmark_tree_root.main_element.set_label_variation("Label_24")
	benchmark_tree_root.main_element.set_collection_icon(BenchmarkCollectionDisplay.TYPES.BENCHMARK)
	benchmark_tree_root.collapsable = false
	
	benchmark_tree_root.connect("pressed", self, "_on_tree_item_pressed")
	tree_container.add_child(benchmark_tree_root)
	
	accounts = benchmark_config_dialog.accounts_checklist.checked_options
	
	checks = {}
	var accounts_id : Array = []
	collapsed_accounts = []
	
	for account in accounts:
		accounts_id.append(account.id)
		var element = new_account_tree_item(account)
		element.set_label_variation("LabelBold")
		var tree_item = benchmark_tree_root.add_sub_element(element)
		tree_item.name = str(account.id)
		tree_item.connect("pressed", self, "_on_tree_item_pressed")
		tree_item.connect("collapsed_changed", self, "_on_account_collapsed_changed", [tree_item, data])
		tree_item.main_element.connect("expand_all", self, "expand_account", [tree_item])
		collapsed_accounts.append(tree_item)
	
	set_top_buttons_disabled(true)
	API.get_benchmark_report(data.id, PoolStringArray(accounts_id), self)
	
	benchmark_tree_root.collapse(false)


func populate_tree_branch(data : Dictionary, root : CustomTreeItem) -> Array:
	var branch_checks : Array = []
	number_of_nodes += 10
	if "children" in data and data.children != null:
		for child in data.children:
			var element = new_check_collection_tree_item(child)
			element.set_collection_icon(BenchmarkCollectionDisplay.TYPES.COLLECTION)
			var item : CustomTreeItem = root.add_sub_element(element)
			item.connect("pressed", self, "_on_tree_item_pressed")
			branch_checks.append_array(populate_tree_branch(child, item))
			number_of_nodes += 9
	elif "checks" in data and data.checks != null:
		for check in data.checks:
			number_of_nodes += 5
			var element = new_check_result_tree_item(check)
			if not checks.has(check):
				continue
			var current_check : Dictionary = checks[check]
			element.severity = current_check["severity"]
			element.title = current_check["title"]
			element.account_id = current_account
			var item : CustomTreeItem = root.add_sub_element(element)
			
			if "failing_resources" in current_check and current_account in current_check["failing_resources"]:
				element.failing_n = current_check["failing_resources"][current_account]
			else:
				element.failing_n = 0
			
			item.connect("pressed", self, "_on_tree_item_pressed")
			branch_checks.append(item)
	return branch_checks


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
	element.account_id = account.id
	return element


func look_for_checks(title : String) -> Array:
	if checks.empty():
		return []
	# Look element in the model
	var element = find_model_element_by_title(title, benchmark_config_dialog.selected_benchmark)
	var check_ids := look_for_checks_in_element(element)
	var check_elements := []
	
	for id in check_ids:
		check_elements.append(checks[id])
		
	check_elements.sort_custom(self, "sort_severity")
	return check_elements


func look_for_checks_in_element(element : Dictionary) -> Array:
	var all_checks: Array = []
	
	if element.empty():
		return []
	
	if "checks" in element and element.checks != null:
		return element["checks"]
	
	for child in element["children"]:
		if "checks" in child and child.checks != null:
			all_checks.append_array(child["checks"])
		else:
			all_checks.append_array(look_for_checks_in_element(child))
	
	return all_checks


func _on_ExportButton_pressed():
	var data : PoolStringArray = ["Severity,Number of Resources Failing,Check Name"]
	
	for row in checks_table_content.get_children():
		var row_data : PoolStringArray = []
		var severity : String = row.severity
		severity = "%d - %s" % [severities.find(severity), severity]
		row_data.append(severity)
		row_data.append(str(row.failing_n))
		row_data.append(row.check_name)
		data.append(row_data.join(","))
	
	if OS.has_feature("HTML5"):
		JavaScript.download_buffer(data.join("\n").to_utf8(), "Checks Report - %s.csv" % Time.get_datetime_string_from_system())


func _on_ExportReportButton_pressed():
	var _checks := look_for_checks(benchmark_tree_root.main_element.title)
	var data : PoolStringArray = ["Severity,Number of Resources Failing,Check Name,Account ID"]
	for check in _checks:
		for account_id in check.failing_resources:
			var row_data : PoolStringArray = []
			var severity : String = "%d - %s" % [severities.find(check.severity), check.severity]
			row_data.append(severity)
			row_data.append(str(check.failing_resources[account_id]))
			row_data.append(check.title)
			row_data.append(account_id)
			data.append(row_data.join(","))
		
	if OS.has_feature("HTML5"):
		JavaScript.download_buffer(data.join("\n").to_utf8(), "Checks Report - %s.csv" % Time.get_datetime_string_from_system())


func set_top_buttons_disabled(disabled : bool):
	export_report_button.disabled = disabled
	benchmark_button.disabled = disabled
	collapse_button.disabled = disabled
	expand_button.disabled = disabled
	filter_combo.disabled = disabled
	failed_indicator.get_node("FailButtonFilter").disabled = disabled
	passed_indicator.get_node("PassButtonFilter").disabled = disabled
	$"%LoadingIndicator".modulate = Color.white if disabled else Color.transparent

func find_model_element_by_title(title : String, model : Dictionary):
	var result : Dictionary = {}
	if model["title"] == title:
		return model

	if "children" in model and model.children != null:
		for element in model["children"]:
			if element["title"] == title:
				result = element
			else:
				result = find_model_element_by_title(title, element)
			if not result.empty():
				break
	return result
	
func get_element_account(element : CustomTreeItem) -> String:
	var parent := element
	while parent != null:
		if parent.main_element is BenchmarkAccountDisplay:
			return parent.main_element.account_id
		parent = parent.parent
	return ""

func sort_severity(a : Dictionary, b : Dictionary):
	if severities.find(a.severity) > severities.find(b.severity):
		return true
	return false


func _on_FailButtonFilter_pressed():
	filter_combo.text = "Failing"


func _on_PassButtonFilter_pressed():
	filter_combo.text = "Passing"


func _on_Timer_timeout():
	if not collapsed_accounts.empty():
		for i in 5:
			if collapsed_accounts.empty():
				break
			collapsed_accounts[0].collapse(false)
			
		$ExpandAccountsTimer.start()
	else:
		emit_signal("all_accounts_expanded")


func _on_BenchmarkConfigPopup_visibility_changed():
	$"%BenchmarkPopupBG".visible = $"%BenchmarkConfigPopup".visible
