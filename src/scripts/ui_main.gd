extends Control


func _ready() -> void:
	_g.connect("fullscreen_hide_menu", self, "_on_fullscreen_hide_menu")
	SaveLoadSettings.connect("settings_loaded", self, "show_connect_popup", [], 4)
	SaveLoadSettings.load_settings()


func show_connect_popup(_found_settings:bool) -> void:
	if !_found_settings:
		var screen_size := OS.get_screen_size()
		if screen_size.y < 900:
			_g.ui_scale = 0.8
		elif screen_size.y <= 1080:
			_g.ui_scale = 1.0
		elif screen_size.y <= 1440:
			_g.ui_scale = 1.2
		else:
			_g.ui_scale = 1.8
			
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


func _on_ConnectPopup_connected():
	UINavigation.on_home_loaded()
