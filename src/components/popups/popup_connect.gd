extends PopupPanel

signal connected

const CONNECT_TEXT = "Connecting to Resoto Core\n%s:%s"
const TEXT_ERROR_CONNECTION = "Could not connect to Resoto Core!\nConnection timed out\nPlease check if adress is correct, ports are open and resotocore is running."

var timeout_timer:= 0.0
var timeout_limit:= 4.0
var info_request : ResotoAPI.Request

onready var status = $"%ConnectStatusLabel"
onready var psk_line_edit = $"%PSKLineEdit"
onready var adress_line_edit = $"%ResotoAdressEdit"
onready var connect_button = $"%ButtonConnect"
onready var show_psk_icon = $"%ShowPSKIcon"


func _ready():
	if modulate != Color.white:
		Style.add(self, Style.find_color(modulate))
	elif self_modulate != Color.white:
		Style.add_self(self, Style.find_color(self_modulate))
	_g.popup_manager.popup_connect = self
	_g.connect("connect_to_core", self, "connect_to_core")


func _on_ButtonConnect_pressed() -> void:
	connect_to_core()


func _on_ConnectPopup_about_to_show() -> void:
	psk_line_edit.text = API.psk
	var protocol:= "https://" if API.use_ssl else "http://"
	adress_line_edit.text = protocol + API.adress + ":" + str(API.port)
	$Content/Margin/Connect/PSK.show()
	$Content/Margin/Connect/Adress.show()
	connect_button.show()
	status.text = "Resoto Core connection settings."


func connect_to_core() -> void:
	$ConnectDelay.start()


func start_connect() -> void:
	$Content/Margin/Connect/PSK.hide()
	$Content/Margin/Connect/Adress.hide()
	connect_button.hide()
	
	JWT.token = ""
	var psk = psk_line_edit.text
	
	if OS.has_feature("HTML5"):
		var adress : String		= JavaScript.eval("getURL()")
		var use_ssl : bool		= JavaScript.eval("getProtocol()") == "https:"
		var port : String		= JavaScript.eval("getPort()")
		if port == "":
			port = "80" if not use_ssl else "443"
		API.connection_config(adress, int(port), psk, use_ssl)
	else:
		var a_t = adress_line_edit.text.strip_edges()
		var adress = a_t.split("://")
		adress.remove(0)
		adress = adress[0].split(":")
		var use_ssl = a_t.begins_with("https:")
		var port = 8900
		if adress.size() > 1:
			port = int(adress[1])
		API.connection_config(adress[0], int(port), psk, use_ssl)
	
	var protocol:= "https://" if API.use_ssl else "http://"
	status.text = CONNECT_TEXT % [(protocol + API.adress), API.port]
	yield(VisualServer, "frame_post_draw")
	$ConnectTimeoutTimer.start()
	
	info_request = API.system_ready(self)
	API._get_infra_info(self)


func _on_get_infra_info_done(_error:int, response):
	if _error == OK:
		InfrastructureInformation.infra_info = response.transformed.result


func _on_system_ready_done(error:int, response:UserAgent.Response) -> void:
	if error:
		if error == 25:
			not_connected(Utils.http_status_to_string(info_request.http_.get_status()))
		else:
			not_connected(Utils.err_enum_to_string(error))
	else:
		if response.status_code == 7:
			get_system_info()
			connected(Utils.http_status_to_string(response.status_code))


func get_system_info():
	API.cli_execute("system info", self)


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		_g.emit_signal("add_toast", "Error in Search", Utils.err_enum_to_string(error), 1, self)
		return
	var response_text:String = _response.transformed.result
	var start_index:int = response_text.find("version: ") + 9
	response_text = response_text.right(start_index)
	var end_index:int = response_text.find("git_hash: ")
	response_text = response_text.left(end_index)
	_g.resotocore_version = response_text
	_g.is_connected_to_resotocore = true
	_g.emit_signal("connected_to_resotocore")


func connected(status_text:String) -> void:
	reset_timer()
	status.text = status_text
	SaveLoadSettings.save_settings()
	_g.popup_manager.on_popup_close()
	emit_signal("connected")


func not_connected(status_text:String) -> void:
	reset_timer()
	status.text = status_text
	$Content/Margin/Connect/PSK.show()
	$Content/Margin/Connect/Adress.show()
	connect_button.show()


func _on_ConnectDelay_timeout():
	start_connect()


func reset_timer():
	$ConnectTimeoutTimer.stop()
	timeout_timer = 0.0


func _on_ConnectTimeoutTimer_timeout():
	timeout_timer += 1.0
	var protocol:= "https://" if API.use_ssl else "http://"
	status.text = CONNECT_TEXT % [(str("(%s) " % timeout_timer) + protocol + API.adress), API.port]
	if timeout_timer >= timeout_limit:
		info_request.cancel(24)


const show_tex = preload("res://assets/icons/icon_128_show.svg")
const hide_tex = preload("res://assets/icons/icon_128_hide.svg")
func _on_ShowPSKIcon_toggled(button_pressed:bool):
	show_psk_icon.icon_tex = hide_tex if button_pressed else show_tex
	psk_line_edit.secret = !button_pressed


func _on_ResotoAdressEdit_text_entered(_new_text):
	start_connect()


func _on_PSKLineEdit_text_entered(_new_text):
	start_connect()
