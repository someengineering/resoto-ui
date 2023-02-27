extends MarginContainer

var benchmark_tree_root : CustomTreeItem = null
var tree_item_scene := preload("res://components/shared/custom_tree_item.tscn")
var check_collection_scene := preload("res://components/benchmark_display/benchmark_check_collection_display.tscn")
var check_result_scene := preload("res://components/benchmark_display/benchmark_check_result_display.tscn")

var last_detect_type := "manual"
var last_detect_command := ""

var sections := {}

var checks := {}
var current_account : String = ""

var benchmarks := {}
var benchmarks_count := 0

var benchmark_model : CustomTreeItem = null

onready var tree_container := $PanelContainer/Content/PanelContainer/TreeContainer

onready var passed_indicator := $PanelContainer/Content/PanelContainer2/HBoxContainer2/PassIndicator
onready var failed_indicator := $PanelContainer/Content/PanelContainer2/HBoxContainer2/FailIndicator

onready var detail_view := $PanelContainer/Content/PanelContainer/DetailView
onready var detail_view_title := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/TitleLabel
onready var detail_view_description := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/DescriptionLabel
onready var detail_view_pass_widget := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/FailingVsPassingWidget
onready var detail_view_severity := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/HBoxContainer/SeverityLabel
onready var status_label := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/HBoxContainer/StatusLabel
onready var detail_remediation_label := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/RemediationLabel
onready var resources_list := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/PanelContainer/ResourcesList
onready var resources_loading_overlay := $PanelContainer/Content/PanelContainer/DetailView/VBoxContainer/PanelContainer/LoadingOverlay
onready var benchmark_config_dialog := $"%BenchmarkConfigDialog"

func _on_get_configs_done(error: int, response):
	if error:
		# TODO handle error
		return
	benchmarks_count = 0
	
	for config in response.transformed.result:
		if config.begins_with("resoto.report.benchmark."):
			API.get_config_id(self, config)
			benchmarks_count += 1


func _on_get_benchmark_report_done(_error: int, response : ResotoAPI.Response, accounts : Array):
	if _error:
		print(response.body.get_string_from_utf8())
		return
	
	var data : Array = response.transformed.result
	var account = "" if accounts.empty() else accounts[0]
	for item in data:
		if "kind" in item and item.kind == "report_check_result":
			var tree_item : CustomTreeItem = checks[account][item.reported.id]
			if item.reported.number_of_resources_failing > 0:
				pass
			tree_item.main_element.failing_n = item.reported.number_of_resources_failing
			tree_item.main_element.title = item.reported.title
			
			var collection = tree_item.parent


func _on_tree_item_pressed(item : CustomTreeItem):
	var element = item.main_element
	
	detail_view_title.raw_text = element.title
	
	if element.passed:
		status_label.text = "Passed!"
	else:
		if "passing_n" in element:
			status_label.text = ("%s Checks Failed" if element.failing_n > 1 else "%s Check Failed") % element.failing_n
		else:
			status_label.text = ("%s Resources Failed" if element.failing_n > 1 else "%s Resource Failed") % element.failing_n
			
	status_label.self_modulate = Color("#44f470") if element.passed else Color("#f44444")
	detail_view_pass_widget.visible = "passing_n" in element
	detail_remediation_label.visible = "remediation_text" in element
	detail_remediation_label.text = ""
	if "remediation_text" in element:
		if element.remediation_url != "":
			detail_remediation_label.bbcode_text = "Fix: [url=%s]%s[/url]" % [element.remediation_url, element.remediation_text]
		else:
			detail_remediation_label.text = "Fix: " + element.remediation_text
	
	if "tooltip" in element:
		detail_view_description.text = element.tooltip
	elif "risk" in element:
		detail_view_description.text = element.risk
	
	if "passing_n" in element:
		detail_view_pass_widget.passing_n = element.passing_n
		detail_view_pass_widget.failing_n = element.failing_n
	
	if "severity" in element:
		detail_view_severity.text = "(Severity: %s)" % element.severity
		var color := Color.white
		match element.severity:
			"low":
				color = Color("#44f470")
			"medium":
				color = Color.orange
			"high":
				color = Color("#f44444")
			"critical":
				color = Color("#f44444")
				detail_view_severity.text = detail_view_severity.text.to_upper()
				
		detail_view_severity.set("custom_colors/font_color", color)
	
	if element is BenchmarkResultDisplay:
		last_detect_type = element.detect.keys()[0]
		last_detect_command = element.detect[last_detect_type]
		if last_detect_type == "resoto":
			API.graph_search(last_detect_command, self)
		elif last_detect_type == "resoto_cmd":
			API.cli_execute(last_detect_command, self)
		
		resources_loading_overlay.visible = true
		get_tree().call_group("FailingResourcesWidget", "hide")
	else:
		get_tree().call_group("FailingResourcesWidget", "hide")
		
func _on_cli_execute_done(error : int, response: ResotoAPI.Response):
	resources_loading_overlay.visible = false
	if error != OK:
		# TODO: manage errors
		return
		
	populate_resources_list(response.transformed.result)

func _on_graph_search_done(error : int, response: ResotoAPI.Response):
	
	resources_loading_overlay.visible = false
	if error != OK:
		# TODO: manage errors
		return
		
	populate_resources_list(response.transformed.result)
		
func populate_resources_list(request_result : Array):
	get_tree().call_group("FailingResourcesWidget", "show")
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
	if last_detect_command == "":
		return
	match last_detect_type:
		"resoto":
			_g.content_manager.change_section_explore("node_list_info")
			_g.content_manager.find_node("NodeListElement").show_list_from_search(last_detect_command)
		"resoto_cmd":
			# TODO, what to do here?
			pass

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

func _on_RemediationLabel_meta_clicked(meta):
	OS.shell_open(meta)


func _on_BenchmarkButton_pressed():
	$Control/BenchmarkConfigPopup.popup_centered()


func _on_AcceptButton_pressed():
	create_benchmark_model(benchmark_config_dialog.selected_benchmark)


func create_benchmark_model(data : Dictionary):
	benchmark_tree_root = tree_item_scene.instance()
	benchmark_tree_root.main_element = new_check_collection_tree_item(data.title)
	tree_container.add_child(benchmark_tree_root)
	
	var accounts : Array = benchmark_config_dialog.accounts_checklist.checked_options
	
	checks = {}
	
	for account in accounts:
		current_account = account
		var element = new_check_collection_tree_item(account)
		var tree_item = benchmark_tree_root.add_sub_element(element)
		populate_tree_branch(data, tree_item)
	API.get_benchmark_report(data.id, PoolStringArray(accounts), self)


func populate_tree_branch(data : Dictionary, root : CustomTreeItem):
	if "children" in data:
		for child in data.children:
			var element = new_check_collection_tree_item(child.title)
			var item = root.add_sub_element(element)
			populate_tree_branch(child, item)
	if "checks" in data:
		for check in data.checks:
			var element = new_check_result_tree_item(check)
			if not current_account in checks:
				checks[current_account] = {}
			checks[current_account][check] = root.add_sub_element(element)

func new_check_collection_tree_item(title : String = ""):
	var element = check_collection_scene.instance()
	element.title = title
	return element

func new_check_result_tree_item(title : String = ""):
	var element = check_result_scene.instance()
	element.title = title
	return element
