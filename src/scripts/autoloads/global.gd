extends Node

signal add_toast
signal toast_created
signal ui_shrink_changed
signal connected_to_resotocore
signal fullscreen_hide_menu
signal close_hamburger_menu
signal resoto_home_visible
signal top_search_update

# Nav Signals
signal nav_change_section
signal nav_change_section_explore

# Explorer Signals
signal explore_node_by_id
signal explore_node_list_data
signal explore_node_list_search
signal explore_node_list_kind
signal explore_node_list_id

const tsdb_metric_prefix:String		 = "resoto_"
const dashboard_config_prefix:String = "resoto.ui.dashboard."

var ui_shrink: float = 1.0 setget set_ui_shrink
var ui_version:String = "3.0.0a0"
var resotocore_version:String = "n/a"
var os = "Windows"
var terminal_scrollback:Array = []
var focus_in_search:bool = false

var is_connected_to_resotocore:bool	= false

# global references
var content_manager: ContentManager	= null
var popup_manager: PopupManager		= null


func set_ui_shrink(new_shrink:float) -> void:
	ui_shrink = new_shrink
	emit_signal("add_toast", "Scale " + str(ui_shrink*100) + "%", "", 3, self, 0.7)
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920,1080), ui_shrink)
