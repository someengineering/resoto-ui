extends PanelContainer

onready var config_menu : PopupMenu = $Title/SideMenu2/Config.get_popup()
var _on_read_ref  : JavaScriptObject

func _ready() -> void:
	config_menu.connect("id_pressed", self, "_on_config_menu_id_pressed")
	if OS.has_feature("HTML5"):
		_on_read_ref = JavaScript.create_callback(self, "_on_file_read_done")
		var file_reader : JavaScriptObject = (JavaScript.get_interface("reader"))
		file_reader.onload = _on_read_ref

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

func _on_config_menu_id_pressed(id : int) -> void:
	match id:
		0:
			pass
		1:
			API.get_model(self)
		2:
			if OS.has_feature("HTML5"):
				JavaScript.eval("uploadFile()", true)
			

func _on_ButtonDocs_pressed() -> void:
	OS.shell_open("https://resoto.com/docs")
	
func _on_get_model_done(error:int, response) -> void:
	JavaScript.download_buffer(response.body,"model.json")
	
func _on_file_read_done(evt):
	# wait for js
	yield(get_tree().create_timer(0.5),"timeout")
	var fileData : PoolByteArray = JavaScript.eval("fileData;", true)
	print(fileData.get_string_from_utf8())
	API.patch_model(fileData.get_string_from_utf8(), self)
	
func _on_patch_model_done(error:int, response) -> void:
	print("done")
	
