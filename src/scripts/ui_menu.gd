extends CanvasLayer

onready var hb_tween = $HamburgerMenu/HamburgerTween
onready var hb_menu = $HamburgerMenu
onready var hb_button = find_node("HamburgerButton")


func _ready() -> void:
	get_tree().root.connect("size_changed", self, "on_ui_shrink_changed")
	_g.connect("ui_shrink_changed", self, "on_ui_shrink_changed")
	init_menu()


func init_menu():
	yield(get_tree(), "idle_frame")
	hb_menu.rect_position.x = -400
	on_ui_shrink_changed()
	$HamburgerMenu/Panel/MenuContent/MenuItems/ResotoUIVersion.text = "Resoto UI v" + _g.ui_version

onready var config_menu : PopupMenu = $Title/SideMenu2/Config.get_popup()

func _ready() -> void:
	config_menu.connect("id_pressed", self, "_on_config_menu_id_pressed")

func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_key_pressed(KEY_CONTROL):
		if event.button_index == BUTTON_WHEEL_UP:
			ui_scale_up()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			ui_scale_down()


func ui_scale_down() -> void:
	var new_shrink = max(_g.ui_shrink-0.1, 0.5)
	_g.ui_shrink = new_shrink
	_g.emit_signal("ui_shrink_changed")
	SaveLoadSettings.save_settings()


func ui_scale_up() -> void:
	var new_shrink = min(_g.ui_shrink+0.1, 4)
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
	_g.content_manager.change_section("config")
	close_menu()


func _on_ButtonDashboards_pressed():
	_g.content_manager.change_section("dashboards")
	close_menu()


func _on_ButtonTerminals_pressed():
	_g.content_manager.change_section("terminals")
	close_menu()

func _on_ButtonMessageLog_pressed():
	_g.content_manager.change_section("message_log")
	close_menu()


func close_menu():
	hb_button.set_pressed(false)


func on_ui_shrink_changed():
	hb_menu.rect_size.y = OS.window_size.y / _g.ui_shrink


func _on_HamburgerButton_hamburger_button_pressed(pressed):
	if not pressed:
		hb_tween.interpolate_property(hb_menu, "rect_position:x", hb_menu.rect_position.x, -400, 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)
	else:
		hb_tween.interpolate_property(hb_menu, "rect_position:x", hb_menu.rect_position.x, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	hb_tween.start()


func _on_ResotoLogo_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		_g.content_manager.change_section("hub")
