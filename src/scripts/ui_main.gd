extends Control

onready var back_button := $MenuBar/MenuContainer/TopMenu/Title/Back
onready var forward_button := $MenuBar/MenuContainer/TopMenu/Title/Forward

func _ready() -> void:
	_g.connect("fullscreen_hide_menu", self, "_on_fullscreen_hide_menu")
	SaveLoadSettings.connect("settings_loaded", self, "show_connect_popup", [], 4)
	SaveLoadSettings.load_settings()
	if not OS.has_feature("HTML5"):
		back_button.visible = true
		forward_button.visible = true
		UINavigation.connect("navigation_index_changed", self, "_on_navigation_index_changed")
		
	
	
func show_connect_popup(_found_settings:bool) -> void:
	if !_found_settings:
		var dpi:int = OS.get_screen_dpi()
		if dpi >= 130:
			_g.ui_shrink = 2.0
		elif dpi >= 90:
			_g.ui_shrink = 1.5
		elif dpi >= 70:
			_g.ui_shrink = 1.0
		SaveLoadSettings.save_settings()
	_g.popup_manager.open_popup("ConnectPopup")
	_g.emit_signal("connect_to_core")
	
	# If we ever need Godot to receive URL parameters:
#	var custom_parameter = JavaScript.eval("getParameter('custom_parameter')")


func _on_fullscreen_hide_menu(is_fullscreen:bool) -> void:
	$MenuBar.visible = !is_fullscreen
	var top_margin:int = 0 if is_fullscreen else _g.TOP_MARGIN
	var side_margin:int = 0 if is_fullscreen else 10
	var content:= $Content/Content
	content.add_constant_override("margin_top", top_margin)
	content.add_constant_override("margin_right", side_margin)
	content.add_constant_override("margin_bottom", side_margin)
	content.add_constant_override("margin_left", side_margin)


func _on_Back_pressed():
	UINavigation.native_navigate("back")


func _on_Forward_pressed():
	UINavigation.native_navigate("forward")


func _on_ConnectPopup_connected():
	UINavigation.on_home_loaded()


func _on_navigation_index_changed(id : int):
	$MenuBar/MenuContainer/TopMenu/Title/Back.disabled = id <= 0
	$MenuBar/MenuContainer/TopMenu/Title/Forward.disabled = UINavigation.navigation_array.size() <= id + 1
	
