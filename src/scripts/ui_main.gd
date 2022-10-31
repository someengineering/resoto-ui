extends Control


func _ready() -> void:
	_g.connect("fullscreen_hide_menu", self, "_on_fullscreen_hide_menu")
	SaveLoadSettings.connect("settings_loaded", self, "_on_settings_loaded", [], CONNECT_ONESHOT)
	SaveLoadSettings.load_settings()


func _on_settings_loaded(_found_settings:bool) -> void:
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
	yield(get_tree(), "idle_frame")
	_g.popup_manager.open_popup("ConnectPopup")
	_g.popup_manager.popup_connect.connect("connected", self, "_connected", [], CONNECT_ONESHOT)
	_g.emit_signal("connect_to_core")
	
	# If we ever need Godot to receive URL parameters:
#	var custom_parameter = JavaScript.eval("getParameter('custom_parameter')")


func _input(event:InputEvent) -> void:
	if (event is InputEventMouseButton
	and event.is_pressed()
	and (Input.is_key_pressed(KEY_CONTROL) or Input.is_key_pressed(KEY_META))):
		if event.button_index == BUTTON_WHEEL_UP:
			ui_scale_up()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			ui_scale_down()


func ui_scale_down() -> void:
	var new_shrink = stepify(max(_g.ui_shrink-0.1, 0.5), 0.1)
	_g.ui_shrink = new_shrink
	_g.emit_signal("ui_shrink_changed")
	SaveLoadSettings.save_settings()


func ui_scale_up() -> void:
	var new_shrink = stepify(min(_g.ui_shrink+0.1, 4), 0.1)
	_g.ui_shrink = new_shrink
	_g.emit_signal("ui_shrink_changed")
	SaveLoadSettings.save_settings()


func _on_fullscreen_hide_menu(is_fullscreen:bool) -> void:
	$MenuBar.visible = !is_fullscreen
	var top_margin:int = 0 if is_fullscreen else _g.TOP_MARGIN
	var side_margin:int = 0 if is_fullscreen else 10
	var content:= $Content/Content
	content.add_constant_override("margin_top", top_margin)
	content.add_constant_override("margin_right", side_margin)
	content.add_constant_override("margin_bottom", side_margin)
	content.add_constant_override("margin_left", side_margin)


func _connected():
	UINavigation.on_home_loaded()
