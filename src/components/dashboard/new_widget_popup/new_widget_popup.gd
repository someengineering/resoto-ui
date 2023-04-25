extends CustomPopupWindowContainer

signal widget_added(widget_data)
signal widget_edited

const title_add = "Add Widget"
const title_edit = "Edit Widget [%s]"
const title_duplicate = "Duplicate Widget [base: %s]"

const HexColorPicker := preload("res://components/shared/hex_color_picker.tscn")
const CheckBoxStyled := preload("res://components/elements/styled/icon_check_button.tscn")
const IntSpinBoxBig := preload("res://components/shared/int_spinbox_big.tscn")
const DataSourceWidget := preload("res://components/dashboard/new_widget_popup/data_source_container.tscn")
const ColorControllerUIScene := preload("res://components/dashboard/new_widget_popup/color_controller_ui.tscn")
const LegendUIScene := preload("res://components/dashboard/new_widget_popup/legend_ui.tscn")

var dashboard_container:DashboardContainer = null setget set_dashboard_container
var current_widget_preview_name : String = "Indicator"
var current_wdiget_properties : Dictionary = {}
var preview_widget : BaseWidget = null
var metrics : Dictionary = {}

var widget_to_edit:Node	= null
var duplicating:bool	= false

var from_date : int
var to_date : int
var interval : int
var dashboard_filters : Dictionary = {
	"cloud" : "",
	"region" : "",
	"account" : ""
}

var query : String = ""

var data_sources_templates : Array = []

var loading_overlay_scene := preload("res://components/dashboard/shared/loading_overlay.tscn")

onready var data_source_container := find_node("DataSources")
onready var widget_type_options := find_node("WidgetType")
onready var preview_container := find_node("PreviewContainer")
onready var widget_name_label := find_node("WidgetNameEdit")
onready var options_container := find_node("Options")
onready var controller_container := $"%ColorControllersContainer"
onready var legends_container := $"%LegendsContainer"
onready var data_source_types := $"%DataSourceTypeOptionButton"
onready var new_data_source_container := $"%NewDataSourceHBox"
onready var template_popup:= $TemplatePopup
onready var template_options:= $TemplatePopup/VBox/TemplateContent
onready var add_data_source_button:= $"%AddDataSourceButton"


func _ready() -> void:
	Style.add_self(self, Style.c.BG_BACK)
	data_sources_templates = Utils.load_json("res://data/data_sources_templates.json")


func set_dashboard_container(_dc:DashboardContainer) -> void:
	dashboard_container = _dc
	widget_type_options.clear()
	for key in dashboard_container.WidgetScenes:
		widget_type_options.add_item(key)


func _on_AcceptButton_pressed() -> void:
	var widget
	
	if widget_to_edit == null or duplicating:
		var widget_scene_type : String = widget_type_options.text if not duplicating else current_widget_preview_name
		widget = dashboard_container.WidgetScenes[widget_scene_type].instance()
	else:
		widget = widget_to_edit.widget
	
	var properties = get_preview_widget_properties()
	
	for key in properties:
		widget[key] = properties[key]
		
	var new_data_sources : Array = []

	for datasource in data_source_container.get_children():
		var ds = datasource.data_source.duplicate()
		ds.copy_data_source(datasource.data_source)
		ds.widget = widget
		new_data_sources.append(ds)
		
	# Look for color controllers
	for child in preview_widget.get_children():
		if child is ColorController:
			widget.get_node(child.name).conditions = child.conditions.duplicate(true)
		
	if widget_to_edit == null or duplicating:
		var widget_data := {
			"scene"			: widget,
			"widget_type"	: widget_type_options.text,
			"title"			: widget_name_label.text,
			"data_sources"	: new_data_sources
		}
		emit_signal("widget_added", widget_data, true)
	else:
		widget_to_edit.title = widget_name_label.text
		widget_to_edit.data_sources.clear()
		widget_to_edit.data_sources = new_data_sources
		widget_to_edit.call_deferred("execute_query")
		widget_to_edit = null
		emit_signal("widget_edited")
	
	_hide_popup()
	
	var event : int 
	if duplicating:
		event = Analytics.EventsDashboard.DUPLICATE_WIDGET
	elif widget_to_edit == null:
		event = Analytics.EventsDashboard.NEW_WIDGET
	else:
		event = Analytics.EventsDashboard.EDIT_WIDGET
		
	Analytics.event(event, {"widget" : widget.widget_type_id})
	
	clear_data_sources()
	preview_widget.queue_free()


func add_widget_popup():
	set_window_title(title_add)
	popup_centered()


func _on_WidgetType_item_selected(_index : int) -> void:
	if widget_type_options.text == current_widget_preview_name:
		return
	
	create_preview(widget_type_options.text)
	update_legends()
	check_for_data_sources()


func create_preview(widget_type : String = "Indicator") -> void:
	if is_instance_valid(preview_widget):
		preview_widget.queue_free()
	
	if widget_to_edit == null:
		preview_widget = dashboard_container.WidgetScenes[widget_type].instance()
	else:
		preview_widget = load(widget_to_edit.widget.filename).instance()
		for key in get_preview_widget_properties(widget_to_edit.widget):
			preview_widget[key] = widget_to_edit.widget[key]
			prints(key, widget_to_edit.widget[key])
			
		for child in widget_to_edit.widget.get_children():
			if child is ColorController:
				preview_widget.get_node(child.name).conditions = child.conditions.duplicate()
	create_properties_options()
	
	preview_widget.is_preview_widget = true
	preview_widget.add_child(loading_overlay_scene.instance())
	preview_container.add_child(preview_widget)
	preview_widget.connect("available_properties_changed", self, "create_properties_options")
	preview_widget.connect("available_properties_changed", self, "update_preview")
	current_widget_preview_name = widget_type
	
	for datasource in data_source_container.get_children():
		if datasource.data_source.type in preview_widget.supported_types:
			datasource.widget = preview_widget
		else:
			datasource.queue_free()
	
	data_source_types.clear()
	for i in preview_widget.supported_types:
		data_source_types.add_item(DataSource.TYPES.keys()[i].capitalize(), i)

	data_source_types.disabled = data_source_types.get_item_count() <= 1
	data_source_types.emit_signal("item_selected", 0)
	update_new_data_vis()
	check_for_data_sources()


func create_properties_options():
	preview_widget.size_flags_vertical = SIZE_EXPAND_FILL
	for option in options_container.get_children():
		option.queue_free()
		
	for controller in controller_container.get_children():
		controller.queue_free()
		
	var found_settings := false
	var show_widget_options_label := false
	for property in preview_widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			var label = Label.new()
			label.text = property.name.capitalize()
			var value = get_control_for_property(property)
			options_container.add_child(label)
			options_container.add_child(value)
			show_widget_options_label = true
			
			value.size_flags_horizontal |= SIZE_SHRINK_END
		elif property.name == "Widget Settings":
			 found_settings = true
			
	for child in preview_widget.get_children():
		if child is ColorController:
			var controller_ui := ColorControllerUIScene.instance()
			controller_ui.color_controller = child
			controller_ui.size_flags_horizontal |= SIZE_EXPAND
			controller_container.add_child(controller_ui)
			controller_ui.connect("reset_color", self, "reset_widget_color")
			
			var conditions_array := []
			
			for i in child.conditions.size():
				conditions_array.append(child.conditions[i])
				
			for condition in conditions_array:
				controller_ui.add_condition(condition[0], condition[1])
				
	$"%WidgetOptionsLabel".visible = show_widget_options_label
	$"%WidgetOptionsPanelContainer".visible = show_widget_options_label

func get_control_for_property(property : Dictionary) -> Control:
	var control : Control
	var control_signal := ""
	
	match property.type:
		TYPE_INT:
			control = IntSpinBoxBig.instance()
			control.size_flags_horizontal = SIZE_FILL
			control.value_to_set = preview_widget[property.name]
			control_signal = "value_changed"
		TYPE_BOOL:
			control = CheckBoxStyled.instance()
			control.pressed = preview_widget[property.name]
			control_signal = "toggled"
		TYPE_STRING:
			control = LineEdit.new()
			control.theme_type_variation = "LineEditCode"
			control.text = preview_widget[property.name]
			control_signal = "text_changed"
		TYPE_COLOR:
			control = HexColorPicker.instance()
			control.color_to_set = preview_widget[property.name]
			control_signal = "color_changed"
	
	control.connect(control_signal, preview_widget, "set_"+property.name)
	control.size_flags_horizontal |= SIZE_EXPAND
	
	return control


func get_preview_widget_properties(widget = preview_widget) -> Dictionary:
	var found_settings := false
	var properties := {}
	for property in widget.get_property_list():
		if found_settings:
			if property.type == TYPE_NIL:
				break
			properties[property.name] = widget[property.name]
		elif property.name == "Widget Settings":
			 found_settings = true
	return properties


func _on_NameEdit_text_changed(new_text : String) -> void:
	if preview_container.get_child_count() > 0:
		$"%WidgetPreviewTitleLabel".text = new_text


func check_for_data_sources():
	$"%DataSourceMissingHintHighlight".visible = data_source_container.get_child_count() == 0
	$"%DataSourceMissingHint".visible = data_source_container.get_child_count() == 0


func _on_get_config_id_done(_error, _response, _config_key) -> void:
	metrics =  _response.transformed.result["resotometrics"]["metrics"]
	for ds in data_source_container.get_children():
		ds.set_metrics(metrics)


func clear_data_sources():
	for data_source in data_source_container.get_children():
		data_source_container.remove_child(data_source)
		data_source.queue_free()
	check_for_data_sources()


func _on_NewWidgetPopup_about_to_show() -> void:
	# Check for dashboard filters:
	var has_filters := false
	if dashboard_filters.cloud != "":
		has_filters = true
		$"%CloudFilterLabel".text = dashboard_filters.cloud
	if dashboard_filters.account != "":
		has_filters = true
		$"%AccountFilterLabel".text = dashboard_filters.account
	if dashboard_filters.region != "":
		has_filters = true
		$"%RegionFilterLabel".text = dashboard_filters.region
	
	$"%CloudLabel".visible = dashboard_filters.cloud != ""
	$"%CloudFilterLabel".visible = dashboard_filters.cloud != ""
	$"%AccountLabel".visible = dashboard_filters.account != ""
	$"%AccountFilterLabel".visible = dashboard_filters.account != ""
	$"%RegionLabel".visible = dashboard_filters.region != ""
	$"%RegionFilterLabel".visible = dashboard_filters.region != ""
	$"%AppliedFilterBox".visible = has_filters
	$"%ExpandGlobalFiltersButton".pressed = false
	$"%DashboardFilters".hide()
	
	widget_name_label.text = ""
	$"%WidgetPreviewTitleLabel".text = ""
	clear_data_sources()
	if widget_to_edit != null:
		current_widget_preview_name = widget_to_edit.widget.widget_type_id
		widget_name_label.text = widget_to_edit.title
		$"%WidgetPreviewTitleLabel".text = widget_to_edit.title
		var current_widget_index : int = dashboard_container.WidgetScenes.keys().find(widget_to_edit.widget.widget_type_id)
		widget_type_options.select(current_widget_index)
		for data_source in widget_to_edit.data_sources:
			var ds = DataSourceWidget.instance()
			ds.datasource_type = data_source.type
			data_source_container.add_child(ds)
			ds.data_source = data_source
			ds.set_metrics(metrics)
			ds.connect("source_changed", self, "update_preview")
			ds.connect("delete_source", self, "delete_datasource")
	else:
		current_widget_preview_name = widget_type_options.text
			
	$"%WidgetTypeVBox".visible = widget_to_edit == null
	create_preview(current_widget_preview_name)
	API.get_config_id(self, "resoto.metrics")
	
	if widget_to_edit != null:
		update_preview()
		
	update_new_data_vis()
	update_legends()
	check_for_data_sources()


func _on_AddDataSource_pressed() -> void:
	if data_source_container.get_child_count() >= preview_widget.max_data_sources:
		_g.emit_signal("add_toast", "Max Data Sources Exceeded", "Can't add more data sources to this kind of widget.", 1, self)
		return
	
	# If no templates are available for the data source, just add a blank one
	if template_options.get_child_count() == 0:
		_on_AddDataSource()
		return
	
	template_popup.popup(Rect2(add_data_source_button.rect_global_position, Vector2.ONE))


func update_legends():
	for legend in legends_container.get_children():
		legends_container.remove_child(legend)
		legend.queue_free()
		
	var idx := 0
	for datasource in data_source_container.get_children():
		var ds = datasource.data_source
		if "legend" in ds and preview_widget.widget_type_id == "Chart":
			var legend_ui = LegendUIScene.instance()
			legend_ui.index = idx
			legend_ui.text = ds.legend
			legend_ui.stack = ds.stacked
			legends_container.add_child(legend_ui)
			ds.connect("last_metric_keys_changed", legend_ui, "update_legend_help")
			legend_ui.connect("legend_changed", datasource, "_on_legend_changed")
			legend_ui.connect("stack_changed", datasource, "_on_stack_changed")
		idx += 1

func _on_TemplateButton_pressed(_template_id:int) -> void:
	_on_AddDataSource(_template_id)


func _on_AddDataSource(template_id:int= -1) -> void:
	template_popup.hide()
	if data_source_container.get_child_count() >= preview_widget.max_data_sources:
		_g.emit_signal("add_toast", "Max Data Sources Exceeded", "Can't add more data sources to this kind of widget.", 1, self)
		return
		
	var ds = DataSourceWidget.instance()
	ds.datasource_type = data_source_types.get_selected_id()
	
	data_source_container.add_child(ds)

	ds.widget = preview_widget
	ds.connect("source_changed", self, "update_preview")
	ds.connect("delete_source", self, "delete_datasource")

	match ds.datasource_type:
		DataSource.TYPES.TIME_SERIES:
			ds.interval = interval
			ds.set_metrics(metrics)

	update_new_data_vis()
	
	var context = {
			"widget" : ds.widget.widget_type_id,
			"datasource_type" : DataSource.TYPES.keys()[ds.datasource_type]
		}
	var event : int = Analytics.EventsDatasource.NEW
	
	if template_id >= 0:
		var template_data : Dictionary = data_sources_templates[template_id]["data"]
		for key in template_data:
			ds.data_source.set(key, template_data[key])
		ds.set_data_source(ds.data_source)
		update_preview()
		event = Analytics.EventsDatasource.NEW_FROM_TEMPLATE
		context["template"] = data_sources_templates[template_id]["Name"]

	Analytics.event(event, context)
	
	update_legends()
	check_for_data_sources()


func delete_datasource(_data_source:Node) -> void:
	_data_source.queue_free()
	yield(_data_source, "tree_exited")
	update_preview()
	Analytics.event(Analytics.EventsDatasource.DELETE)
	update_legends()
	check_for_data_sources()


func update_new_data_vis():
	yield(VisualServer, "frame_post_draw")
	new_data_source_container.visible = data_source_container.get_child_count() < preview_widget.max_data_sources


func reset_widget_color():
	if preview_widget != null and preview_widget.has_method("reset_color"):
		preview_widget.reset_color()


func update_preview() -> void:
	update_new_data_vis()
		
	if not is_instance_valid(preview_widget):
		return
		
	if preview_widget.has_method("clear_series"):
		preview_widget.clear_series()
	
	for datasource in data_source_container.get_children():
		var attr := {}
		match datasource.data_source.type:
			DataSource.TYPES.TIME_SERIES:
				attr["interval"] = interval
				attr["from"] = from_date
				attr["to"] = to_date
			
		datasource.data_source.make_query(dashboard_filters, attr)
		
		if not datasource.data_source.is_connected("query_status", self, "_on_data_source_query_status"):
			datasource.data_source.connect("query_status", self, "_on_data_source_query_status", [], CONNECT_ONESHOT)
		preview_widget.get_node("LoadingOverlay").show()


func _on_data_source_query_status(_status:int, _title:String, _message:=""):
	var querying := false
	for datasource in data_source_container.get_children():
		var ds = datasource.data_source
		if ds.is_executing_query():
			querying = true
			break
			
	if not querying:
		preview_widget.get_node("LoadingOverlay").hide()
	
func duplicate_widget(widget) -> void:
	duplicating = true
	widget_to_edit = widget
	popup_centered()
	set_window_title(title_duplicate % [widget.widget.widget_type_id])


func edit_widget(widget) -> void:
	widget_to_edit = widget
	popup_centered()
	set_window_title(title_edit % [widget.widget.widget_type_id])


func _close_popup():
	_on_NewWidgetPopup_popup_hide()


func _on_NewWidgetPopup_popup_hide():
	duplicating = false
	widget_to_edit = null
	if preview_widget != null and is_instance_valid(preview_widget):
		preview_widget.queue_free()
	clear_data_sources()


func _on_DataSourceTypeOptionButton_item_selected(_index):
	for c in template_options.get_children():
		c.queue_free()
	var data_source_type = data_source_types.get_selected_id()
	var templates_available:= false
	for i in data_sources_templates.size():
		var data : Dictionary = data_sources_templates[i]
		if data["data"]["type"] == data_source_type and widget_type_options.text in data["Widgets"]:
			var new_template = Button.new()
			new_template.text = data["Name"]
			new_template.connect("pressed", self, "_on_TemplateButton_pressed", [i])
			new_template.set_meta("template_id", i)
			new_template.align = Button.ALIGN_LEFT
			template_options.add_child(new_template)
			templates_available = true
	$"%TemplatesAvailableLabel".visible = templates_available


func _on_ExpandGlobalFiltersButton_pressed():
	$"%DashboardFilters".visible = $"%ExpandGlobalFiltersButton".pressed
