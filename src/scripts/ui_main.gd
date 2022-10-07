extends Control


func _ready() -> void:
	_g.connect("fullscreen_hide_menu", self, "_on_fullscreen_hide_menu")
	SaveLoadSettings.connect("settings_loaded", self, "show_connect_popup", [], 4)
	SaveLoadSettings.load_settings()
	
	
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
	
	# If we ever need Godot to receive URL parameters:
#	var custom_parameter = JavaScript.eval("getParameter('custom_parameter')")

func _on_fullscreen_hide_menu(is_fullscreen:bool) -> void:
	$MenuBar.visible = !is_fullscreen
	var top_margin:int = 0 if is_fullscreen else 40
	var side_margin:int = 0 if is_fullscreen else 10
	var content:= $Content/Content
	content.add_constant_override("margin_top", top_margin)
	content.add_constant_override("margin_right", side_margin)
	content.add_constant_override("margin_bottom", side_margin)
	content.add_constant_override("margin_left", side_margin)
