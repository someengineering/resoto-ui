extends Node

# Connection
signal connected_to_resotocore
signal connect_to_core

# Toasts
signal add_toast
signal toast_created
signal toast_click
signal toast_show_saved
signal toast_close_all

# UI and fullscreen
signal ui_scale_changed
signal ui_scale_increase
signal ui_scale_decrease
signal fullscreen_hide_menu
signal close_hamburger_menu
signal resoto_home_visible
signal top_search_update

# Tooltip Signals
signal tooltip
signal tooltip_link
signal tooltip_hide
signal tooltip_error
signal tooltip_node

# Nav Signals
signal nav_change_section
signal nav_change_section_explore

# Explorer Signals
signal explore_node_by_id
signal explore_node_list
signal explore_node_list_data
signal explore_node_list_search
signal explore_node_list_from_node
signal explore_node_list_kind
signal explore_node_list_id

# Aggregation View Signals
signal aggregation_view_show

# Setup Wizard Signals
signal setup_wizard_start
signal setup_wizard_done
signal setup_wizard_minimized
signal collect_run_finished
signal collect_run_display_all_done

# Websocket
signal websocket_message

# Messaging
signal text_to_clipboard

# Resh Lite Popup
signal resh_lite_popup
signal resh_lite_popup_with_cmd
signal resh_lite_popup_hide


const TOP_MARGIN:int = 50
const tsdb_metric_prefix:String		 = "resoto_"
const dashboard_config_prefix:String = "resoto.ui.dashboard."
const discord_link:String			 = "https://discord.gg/someengineering"


var ui_test_mode: bool = false
var ui_scale: float = 1.0 setget set_ui_scale
var ui_version:String = "3.6.2"
var resotocore_version:String = "n/a"
var os = "Windows"
var browser = ""
var terminal_scrollback:Array = []
var focus_in_search:bool = false
var resoto_model : Dictionary = {}

var is_connected_to_resotocore:bool	= false

# global references
var content_manager: ContentManager	= null
var popup_manager: PopupManager		= null

var authorized : bool = false


func set_ui_scale(_ui_scale:float) -> void:
	ui_scale = _ui_scale
	emit_signal("add_toast", "Scale " + str(ui_scale*100) + "%", "", 3, self, 0.7)
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920,1080), ui_scale)


var time_before = 0.0
func start_benchmark():
	time_before = OS.get_ticks_msec()

func stop_benchmark(_text:String = "-"):
	var total_time = OS.get_ticks_msec() - time_before
	print("Benchmark (%s): %s" % [_text, str(total_time)])
