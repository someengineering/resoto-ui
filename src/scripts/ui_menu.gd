extends CanvasLayer

export (bool) var force_hide_message_log:= false

onready var hb_tween = $HamburgerMenu/HamburgerTween
onready var hb_menu = $HamburgerMenu
onready var hb_button = find_node("HamburgerButton")
onready var click_detection = find_node("ClickDetection")
onready var shadow_side = find_node("ShadowSide")
onready var search_box = $"%TopMenuFullTextSearch"
onready var main_logo = $"%MainResotoLogo"


func _ready() -> void:
	_g.connect("close_hamburger_menu", self, "close_menu")
	_g.connect("top_search_update", self, "_on_top_search_update")
	_g.connect("resoto_home_visible", self, "_on_resoto_home_visible")
	$"%HamburgerMenuItems/ButtonMessageLog".visible = OS.has_feature("editor") and not force_hide_message_log
	
	get_tree().root.connect("size_changed", self, "on_ui_shrink_changed")
	_g.connect("ui_shrink_changed", self, "on_ui_shrink_changed")
	init_menu()


func init_menu():
	yield(get_tree(), "idle_frame")
	hb_menu.rect_position.x = -400
	on_ui_shrink_changed()
	$"%HamburgerMenuItems/ResotoUIVersion".text = "Resoto UI v" + _g.ui_version


func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_key_pressed(KEY_CONTROL):
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


func _on_ButtonDocs_pressed() -> void:
	OS.shell_open("https://resoto.com/docs")


func _on_config_menu_id_pressed(id : int) -> void:
	match id:
		0:
			pass
		1:
			# Download the model
			API.get_model(self)
		2:
			# Patch model by upload
			HtmlFiles.upload_file(self)
		3:
			# Upload Graph popup
			_g.popup_manager.open_popup("GraphPopup")


# Download the model
func _on_get_model_done(_error:int, response) -> void:
	JavaScript.download_buffer(response.body,"model.json")

# Patch model by upload
func _on_upload_file_done(_filename:String, data) -> void:
	API.patch_model(data, self)


func _on_patch_model_done(_error:int, _response) -> void:
	print("Done patching model")


func _on_ButtonConfig_pressed():
	_g.emit_signal("nav_change_section", "config")
	close_menu()


func _on_ButtonDashboards_pressed():
	_g.emit_signal("nav_change_section", "dashboards")
	close_menu()


func _on_ButtonTerminals_pressed():
	_g.emit_signal("nav_change_section", "terminals")
	close_menu()


func _on_ButtonMessageLog_pressed():
	_g.emit_signal("nav_change_section", "message_log")
	close_menu()


func close_menu():
	if hb_button.pressed:
		hb_button.pressed = false


func on_ui_shrink_changed():
	hb_menu.rect_size.y = OS.window_size.y / _g.ui_shrink


func _on_HamburgerButton_hamburger_button_pressed(pressed:bool):
	if not pressed:
		shadow_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
		click_detection.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb_tween.interpolate_property(hb_menu, "rect_position:x", hb_menu.rect_position.x, -400, 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)
	else:
		shadow_side.mouse_filter = Control.MOUSE_FILTER_PASS
		click_detection.mouse_filter = Control.MOUSE_FILTER_PASS
		hb_tween.interpolate_property(hb_menu, "rect_position:x", hb_menu.rect_position.x, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	hb_tween.start()


func _on_ResotoLogo_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		_g.emit_signal("nav_change_section", "home")
		close_menu()


func _on_click_detection_gui_input(event:InputEventMouseButton):
	if hb_button.pressed and event is InputEventMouseButton and event.is_pressed():
		hb_button.pressed = false


func _on_top_search_update(_text:String) -> void:
	search_box.text = _text


func _on_resoto_home_visible(_visibility:bool) -> void:
	search_box.modulate.a = 0 if _visibility else 1
	search_box.mouse_filter = Control.MOUSE_FILTER_IGNORE if _visibility else Control.MOUSE_FILTER_PASS
	main_logo.modulate.a = 0 if _visibility else 1
	main_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE if _visibility else Control.MOUSE_FILTER_PASS


func _on_ButtonExplore_pressed():
	_g.emit_signal("nav_change_section_explore", "last")
	close_menu()
