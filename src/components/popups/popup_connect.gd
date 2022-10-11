extends VBoxContainer

signal connected

const CONNECT_TEXT = "Connecting to Resoto Core...\n({0}s) {1}:{2}"
const TEXT_ERROR_CONNECTION = "Could not connect to Resoto Core!\nConnection timed out\nPlease check if adress is correct, ports are open and resotocore is running."

var timeout_timer:= 0.0
var timeout_limit:= 5.0
var info_request : ResotoAPI.Request

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
	$ConnectDelay.start()


func connect_to_core() -> void:
	$Label.hide()
	$PSKLineEdit.hide()
	$ButtonConnect.hide()
	
	JWT.token = ""
	API.psk = psk_line_edit.text
	
	if OS.has_feature("HTML5"):
		API.adress = JavaScript.eval("getURL()")
		var protocol = JavaScript.eval("getProtocol()")
		API.use_ssl = protocol == "https:"
	
	status.text = CONNECT_TEXT.format(["0", API.adress, API.port])
	yield(VisualServer, "frame_post_draw")
	$ConnectTimeoutTimer.start()
	
	info_request = API.cli_info(self)
	API._get_infra_info(self)


func _on_get_infra_info_done(_error:int, response):
	if _error == OK:
		InfrastructureInformation.infra_info = response.transformed.result


func _on_cli_info_done(error:int, response:UserAgent.Response) -> void:
	if error:
		not_connected(Utils.err_enum_to_string(error))
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
	emit_signal("connected")


func not_connected(status_text:String) -> void:
	reset_timer()
	status.text = status_text
	$Label.show()
	$PSKLineEdit.show()
	$ButtonConnect.show()


func _on_ConnectDelay_timeout():
	connect_to_core()


func reset_timer():
	$ConnectTimeoutTimer.stop()
	timeout_timer = 0.0


func _on_ConnectTimeoutTimer_timeout():
	timeout_timer += 1.0
	status.text = CONNECT_TEXT.format([timeout_timer, API.adress, API.port])
	if timeout_timer >= timeout_limit:
		info_request.cancel(24)
	
