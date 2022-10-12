extends CanvasLayer
class_name ContentManager

onready var sections = {
	"terminals": $Content/TerminalManager,
	"dashboards": $Content/DashBoardManager,
	"config": $Content/ConfigManager,
	"message_log": $Content/MessageLog,
	"node_single_info": $Content/NodeSingleInfo,
	"node_list_info": $Content/NodeListElement,
	"hub": $Content/ResotoHub
}

var active_section = "terminal"

onready var content_sections = $Content


func _enter_tree():
	_g.content_manager = self


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
