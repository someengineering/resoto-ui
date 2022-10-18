extends CanvasLayer
class_name ContentManager

onready var sections = {
	"terminals": $Content/TerminalManager,
	"dashboards": $Content/DashBoardManager,
	"config": $Content/ConfigManager,
	"message_log": $Content/MessageLog,
	"node_single_info": $Content/NodeSingleInfo,
	"node_list_info": $Content/NodeListElement,
	"home": $Content/ResotoHome
}

var active_section:= "terminal"
var last_visited_explore_section:= "none"
onready var content_sections = $Content


func _enter_tree():
	_g.content_manager = self


func _ready():
	_g.connect("nav_change_section", self, "change_section")
	_g.connect("nav_change_section_explore", self, "change_section_explore")


func change_section(new_section:String):
	if new_section == active_section or not sections.has(new_section):
		return
	
	active_section = new_section
	for c in content_sections.get_children():
		c.hide()
	
	if sections[active_section].has_method("start"):
		sections[active_section].start()
	else:
		sections[active_section].show()


func change_section_explore(type:String):
	if type == "last":
		if last_visited_explore_section == "none":
			_g.emit_signal("explore_node_by_id", "root")
			last_visited_explore_section = "node_single_info"
		else:
			change_section(last_visited_explore_section)
	elif type == "node_single_info" or type == "node_list_info":
		prints(type)
		last_visited_explore_section = type
		change_section(type)
		
