extends CanvasLayer
class_name ContentManager

onready var sections = {
	"resoto_shell_lite": $Content/TerminalComponent,
	"dashboards": $Content/DashBoardComponent,
	"config": $Content/ConfigComponent,
	"message_log": $Content/LogComponent,
	"node_single_info": $Content/NodeSingleInfoComponent,
	"node_list_info": $Content/NodeListElementComponent,
	"setup_wizard": $Content/SetupWizardComponent,
	"jobs": $Content/JobsComponent,
	"aggregation_view": $Content/AggregationViewComponent,
	"home": $Content/HomeComponent,
	"benchmark": $Content/BenchmarkComponent
}

var active_section:= "home"
var last_visited_explore_section:= "none"
onready var content_sections = $Content


func _enter_tree():
	_g.content_manager = self


func _ready():
	_g.connect("nav_change_section", self, "change_section")
	_g.connect("nav_change_section_explore", self, "change_section_explore")
	UINavigation.connect("navigate", self, "_on_navigate")


func change_section(new_section:String, update_navigation_state := true):
	if new_section == active_section or not sections.has(new_section):
		return
	
	if "can_leave_section" in sections[active_section] and not sections[active_section].can_leave_section:
		sections[active_section].leave_section_request()
		yield(sections[active_section], "leave_request_handled")
		if sections[active_section].can_leave_section:
			change_section(new_section, update_navigation_state)
		else:
			return
	
	if sections[active_section].has_method("leave_section"):
		sections[active_section].leave_section()
	
	active_section = new_section
	for c in content_sections.get_children():
		c.hide()
	
	_g.emit_signal("tooltip_hide")
	sections[active_section].show()
	
	if update_navigation_state:
		if not sections[active_section] is ComponentContainer:
			var args := {
				"view" : active_section
			}
			
			UINavigation.change_title(active_section.capitalize())
			UINavigation.set_current_navigation_state(args)


func change_section_explore(type:String):
	if type == "last":
		if last_visited_explore_section == "none":
			_g.emit_signal("explore_node_by_id", "root")
			last_visited_explore_section = "node_single_info"
		else:
			change_section(last_visited_explore_section)
	elif type == "root":
		_g.emit_signal("explore_node_by_id", "root", true, "treemap")
		last_visited_explore_section = "node_single_info"
	elif type == "node_single_info" or type == "node_list_info":
		last_visited_explore_section = type
		change_section(type)


func _on_navigate(navigation_args : Dictionary):
	if navigation_args["view"] == "":
		navigation_args["view"] = "home"
	
	var section = sections[navigation_args["view"]]
	
	change_section(navigation_args["view"], false)
	
	if section is ComponentContainer:
		section.navigation_arguments = navigation_args
		section.apply_navigation_arguments()
	
