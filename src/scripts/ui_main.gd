extends Control


func _ready() -> void:
	_g.connect("fullscreen_hide_menu", self, "_on_fullscreen_hide_menu")
	_g.connect("ui_scale_increase", self, "ui_scale_up")
	_g.connect("ui_scale_decrease", self, "ui_scale_down")
	SaveLoadSettings.connect("settings_loaded", self, "_on_settings_loaded", [], CONNECT_ONESHOT)
	SaveLoadSettings.load_settings()
	
	# Check errors of previous session
	if OS.has_feature("HTML5"):
		var has_errors = JavaScript.eval('"error" in window.localStorage')
		if has_errors:
			var errors = str2var(JavaScript.eval('window.localStorage.getItem("error")'))
			
			var properties := {
				"errors" : errors
			}
			var counters := {
				"errors-number" : errors.size()
			}
			
			Analytics.event(Analytics.EventsUI.ERROR, properties, counters)
			
			JavaScript.eval('window.localStorage.removeItem("error")')
			
	var properties := {
		"UI version" : _g.ui_version
	}
	
	if OS.has_feature("HTML5"):
		properties["OS"] = JavaScript.eval("getOS()")
		properties["browser"] = JavaScript.eval("getBrowser()")
		_g.browser = properties["browser"]
	else:
		properties["OS"] = OS.get_name()
		
	Analytics.event(Analytics.EventsUI.STARTED, properties)


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
	
	if event is InputEventKey:
		if event.is_action_pressed("ui_zoom_plus"):
			ui_scale_up()
		elif event.is_action_pressed("ui_zoom_minus"):
			ui_scale_down()


func ui_scale_down() -> void:
	_g.ui_scale = stepify(max(_g.ui_scale-0.1, 0.5), 0.1)
	_g.emit_signal("ui_scale_changed")
	SaveLoadSettings.save_settings()


func ui_scale_up() -> void:
	_g.ui_scale = stepify(min(_g.ui_scale+0.1, 4), 0.1)
	_g.emit_signal("ui_scale_changed")
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
	
