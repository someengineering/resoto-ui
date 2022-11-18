extends CanvasLayer

export (bool) var force_hide_message_log:= false

var is_search_visible : bool = true

onready var hb_tween = $HamburgerMenu/HamburgerTween
onready var hb_menu = $HamburgerMenu
onready var hb_button = find_node("HamburgerButton")
onready var click_detection = find_node("ClickDetection")
onready var shadow_side = find_node("ShadowSide")
onready var search_box = $"%TopMenuFullTextSearch"
onready var main_logo = $"%MainResotoLogo"
onready var back_button := $"%HistoryBackButton"
onready var forward_button := $"%HistoryFwdButton"
onready var history_buttons := $"%HistoryButtons"


func _ready() -> void:
	_g.connect("close_hamburger_menu", self, "close_menu")
	_g.connect("top_search_update", self, "_on_top_search_update")
	_g.connect("resoto_home_visible", self, "_on_resoto_home_visible")
	
	get_tree().root.connect("size_changed", self, "on_ui_scale_changed")
	_g.connect("ui_scale_changed", self, "on_ui_scale_changed")
	init_menu()
	
	history_buttons.visible = not OS.has_feature("HTML5")
	if not OS.has_feature("HTML5"):
		UINavigation.connect("navigation_index_changed", self, "_on_navigation_index_changed")


func init_menu():
	yield(get_tree(), "idle_frame")
	hb_menu.rect_position.x = -400
	on_ui_scale_changed()
	$"%HamburgerMenuItems/ResotoUIVersion".text = "Resoto UI v" + _g.ui_version


func _unhandled_input(event:InputEvent) -> void:
	if _g.popup_manager.current_popup != null:
		return
	
	if event.is_action_pressed("ui_cancel"):
		hb_button.pressed = !hb_button.pressed
		get_tree().set_input_as_handled()
	
	if event.is_action_pressed("search") and is_search_visible:
		search_box.grab_focus()
		get_tree().set_input_as_handled()


func _on_ButtonDocs_pressed() -> void:
	OS.shell_open("https://resoto.com/docs")


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


func on_ui_scale_changed():
	hb_menu.rect_size.y = OS.window_size.y / _g.ui_scale
	$"%ZoomScaleLabel".text = str(_g.ui_scale*100) + "%"


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
	is_search_visible = !_visibility
	search_box.modulate.a = 0 if _visibility else 1
	search_box.mouse_filter = Control.MOUSE_FILTER_IGNORE if _visibility else Control.MOUSE_FILTER_PASS
	main_logo.modulate.a = 0 if _visibility else 1
	main_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE if _visibility else Control.MOUSE_FILTER_PASS


func _on_ButtonExplore_pressed():
	_g.emit_signal("nav_change_section_explore", "last")
	close_menu()


func _on_HistoryBackButton_pressed():
	UINavigation.native_navigate("back")


func _on_HistoryFwdButton_pressed():
	UINavigation.native_navigate("forward")


func _on_navigation_index_changed(id : int):
	back_button.can_press = id > 0
	forward_button.can_press = !(UINavigation.navigation_array.size() <= id + 1)


func _on_ButtonUISettings_pressed():
	_g.popup_manager.open_popup("UISettingsPopup")
	close_menu()


func _on_ButtonUIScaleMinus_pressed():
	_g.emit_signal("ui_scale_decrease")


func _on_ButtonUIScalePlus_pressed():
	_g.emit_signal("ui_scale_increase")


# This still needs to be build back into the UI, but for now the PR is on ice.
#func _on_config_menu_id_pressed(id : int) -> void:
#	match id:
#		0:
#			pass
#		1:
#			# Download the model
#			API.get_model(self)
#		2:
#			# Patch model by upload
#			HtmlFiles.upload_file(self)
#		3:
#			# Upload Graph popup
#			_g.popup_manager.open_popup("GraphPopup")
#
#
## Download the model
#func _on_get_model_done(_error:int, response) -> void:
#	JavaScript.download_buffer(response.body,"model.json")
#
## Patch model by upload
#func _on_upload_file_done(_filename:String, data) -> void:
#	API.patch_model(data, self)
#
#
#func _on_patch_model_done(_error:int, _response) -> void:
#	print("Done patching model")
