extends VBoxContainer

var TerminalScene: PackedScene = preload("res://components/terminal/component_terminal.tscn")

var is_popup := false

var terminals: Array = []
var _active_tab_id: int = -1

onready var tabs: Tabs = find_node("TerminalTabs")
onready var container = find_node("TerminalContainer")

func _ready() -> void:
	add_new_terminal_tab()


func update_size() -> void:
	var tab_count =  tabs.get_tab_count()
	if tab_count == 0:
		tabs.rect_min_size.x = 0
		return
	
	var total_size_x : float = 0.0
	for i in tab_count:
		total_size_x += tabs.get_tab_rect(i).size.x
	tabs.rect_min_size.x = clamp(40 + total_size_x, 0, rect_size.x-30)


func deactivate_all_terminals() -> void:
	for terminal in terminals:
		if terminal is TerminalComponent:
			terminal.hide()
			terminal.terminal_active = false


func change_name(_new_name:String) -> void:
	tabs.set_tab_title(_active_tab_id, _new_name)


func add_new_terminal_tab() -> void:
	tabs.add_tab("Terminal " + str(tabs.get_tab_count()+1))
	var new_terminal = TerminalScene.instance()
	new_terminal.is_popup = is_popup
	new_terminal.connect("rename_terminal", self, "on_rename_terminal", [new_terminal])
	terminals.append(new_terminal)
	container.add_child(new_terminal)
	update_size()
	change_active_tab(tabs.get_tab_count()-1, true)


func on_rename_terminal(_new_name:String, _terminal:TerminalComponent) -> void:
	tabs.set_tab_title(terminals.find(_terminal), _new_name)
	update_size()


func change_active_tab(tab:int, update_tab:bool =false) -> void:
	_active_tab_id = tab
	if update_tab:
		tabs.current_tab = tab
	deactivate_all_terminals()
	terminals[tab].show()
	terminals[tab].terminal_active = true


func _on_TerminalTabs_tab_changed(tab:int) -> void:
	change_active_tab(tab)


func _on_TerminalTabs_tab_close(tab:int) -> void:
	terminals[tab].queue_free()
	terminals.remove(tab)
	tabs.remove_tab(tab)
	update_size()
	if tabs.get_tab_count() > 0:
		change_active_tab( int(max(tab-1, 0)), true )


func _on_NewTabButton_pressed() -> void:
	add_new_terminal_tab()


func _on_TerminalTabs_reposition_active_tab_request(idx_to:int) -> void:
	var curr_terminal = terminals[_active_tab_id]
	terminals.remove(_active_tab_id)
	terminals.insert(idx_to, curr_terminal)
	_active_tab_id = idx_to
