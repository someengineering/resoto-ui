extends VBoxContainer

const CONNECT_TEXT = "Connecting to Resoto Core...\n({0}s) {1}:{2}"
const TEXT_ERROR_CONNECTION = "Could not connect to Resoto Core!\nConnection timed out\nPlease check if adress is correct, ports are open and resotocore is running."

onready var status = $ConnectStatusLabel
onready var psk_line_edit = $PSKLineEdit

func _ready() -> void:
	_g.popup_manager.popup_connect = self


func _on_PSKLineEdit_text_entered(_new_text) -> void:
	connect_to_core()


func _on_ButtonConnect_pressed() -> void:
	connect_to_core()


func _on_ConnectPopup_about_to_show() -> void:
	psk_line_edit.text = API.psk
	connect_to_core()


func connect_to_core() -> void:
	$Label.hide()
	$PSKLineEdit.hide()
	$ButtonConnect.hide()
	
	JWT.token = ""
	API.psk = psk_line_edit.text
	
	if OS.has_feature("HTML5"):
		API.adress = JavaScript.eval("getURL()")
		
	status.text = CONNECT_TEXT.format(["0", API.adress, API.port])
	yield(VisualServer, "frame_post_draw")
	
	API.cli_info(self)


func _on_cli_info_done(error:int, response:UserAgent.Response) -> void:
	if error:
		not_connected("")
	else:
		if response.status_code == 7:
			if response.transformed["result"].left(3) == "401":
				not_connected("401: Unauthorized")
				return
			connected(Utils.http_status_to_string(response.status_code))


func connected(status_text:String) -> void:
	status.text = status_text
	SaveLoadSettings.save_settings()
	_g.popup_manager.on_popup_close()


func not_connected(status_text:String) -> void:
	status.text = status_text
	$Label.show()
	$PSKLineEdit.show()
	$ButtonConnect.show()
