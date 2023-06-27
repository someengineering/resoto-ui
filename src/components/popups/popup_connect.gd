extends PopupPanel

signal connected

const CONNECT_TEXT = "Connecting to Resoto Core\n%s:%s"
const TEXT_ERROR_CONNECTION = "Could not connect to Resoto Core!\nConnection timed out\nPlease check if adress is correct, ports are open and resotocore is running."

var timeout_timer:= 0.0
var timeout_limit:= 4.0
var info_request : ResotoAPI.Request
var infra_request : ResotoAPI.Request
var is_connected := false

onready var address_line_edit := $"%ResotoAdressEdit"

func _ready():
	
	JWT.token = ""
	if modulate != Color.white:
		Style.add(self, Style.find_color(modulate))
	elif self_modulate != Color.white:
		Style.add_self(self, Style.find_color(self_modulate))
	_g.popup_manager.popup_connect = self
	_g.connect("connect_to_core", self, "connect_to_core")


func _on_ButtonConnect_pressed() -> void:
	connect_to_core()


func _on_ConnectPopup_about_to_show() -> void:
	var protocol:= "https://" if API.use_ssl else "http://"
	address_line_edit.text = protocol + API.adress + ":" + str(API.port)
	if OS.has_feature("html5"):
		$Content/Margin/Login/Adress/ResotoAdressEdit.text = JavaScript.eval("window.location.origin")
		$Content/Margin/Login/Adress/ResotoAdressEdit.editable = false

	_g.emit_signal("resh_lite_popup_hide")


func connect_to_core() -> void:
	$ConnectDelay.start()


func start_connect() -> void:
	if info_request:
		info_request.cancel(ERR_PRINTER_ON_FIRE)
	if infra_request:
		infra_request.cancel(ERR_PRINTER_ON_FIRE)
	
	if OS.has_feature("HTML5"):
		var adress : String		= JavaScript.eval("getURL()")
		var use_ssl : bool		= JavaScript.eval("getProtocol()") == "https:"
		var port : String		= JavaScript.eval("getPort()")
		if port == "":
			port = "80" if not use_ssl else "443"
		API.connection_config(adress, int(port), use_ssl)
		$Content/Margin/Login/Adress/ResotoAdressEdit.text = JavaScript.eval("window.location.origin")
		$Content/Margin/Login/Adress/ResotoAdressEdit.editable = false

	else:
		var a_t = address_line_edit.text.strip_edges()
		var adress = a_t.split("://")
		adress.remove(0)
		adress = adress[0].split(":")
		var use_ssl = a_t.begins_with("https:")
		var port = 8900
		if adress.size() > 1:
			port = int(adress[1])
		API.connection_config(adress[0], int(port), use_ssl)
	var protocol:= "https://" if API.use_ssl else "http://"
	address_line_edit.text = protocol + API.adress + ":" + str(API.port)
	yield(VisualServer, "frame_post_draw")
	$ConnectTimeoutTimer.start()
	
	info_request = API.system_ready(self)
	infra_request = API._get_infra_info(self)


func _on_get_infra_info_done(_error:int, response):
	if _error == OK:
		InfrastructureInformation.infra_info = response.transformed.result


func _on_system_ready_done(error:int, response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		if error == 25:
			not_connected()
		else:
			not_connected()
	else:
		if response.status_code == 7:
			get_system_info()


func get_system_info():
	API.cli_execute("system info", self)


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if is_connected:
		return
	if error:
		if _response.response_code == 401:
			not_connected()
		return
	is_connected = true
	var response_text:String = _response.transformed.result
	var start_index:int = response_text.find("version: ") + 9
	response_text = response_text.right(start_index)
	var end_index:int = response_text.find("git_hash: ")
	response_text = response_text.left(end_index)
	_g.resotocore_version = response_text
	_g.is_connected_to_resotocore = true
	connected()
	_g.emit_signal("connected_to_resotocore")


func connected() -> void:
	reset_timer()
	SaveLoadSettings.save_settings()
	_g.popup_manager.on_popup_close()
	emit_signal("connected")
	$PingTimer.start()


func not_connected() -> void:
	reset_timer()
	$PingTimer.stop()
	if not is_connected and not visible:
		start_connect()


func _on_ConnectDelay_timeout():
	start_connect()
	return


func reset_timer():
	$ConnectTimeoutTimer.stop()
	timeout_timer = 0.0


func _on_ConnectTimeoutTimer_timeout():
	timeout_timer += 1.0
	if timeout_timer >= timeout_limit:
		info_request.cancel(24)


func _on_ResotoAdressEdit_text_entered(_new_text):
	start_connect()


func _on_PSKLineEdit_text_entered(_new_text):
	start_connect()


func _on_PingTimer_timeout():
	API.ping(self)


func _on_ping_done(_error: int, _r:ResotoAPI.Response):
	if not is_connected:
		return
	if _error or _r.response_code != 200 or _r.body.get_string_from_utf8() != "pong":
		is_connected = false
		_g.emit_signal("add_toast", "Lost connection to Resoto Core.", "", 2)
		$PingTimer.stop()
		_g.popup_manager.open_popup("ReconnectPopup")
		start_connect()


func _on_LoginButton_pressed():
	if OS.has_feature("HTML5"):
		HtmlFiles.remove_from_local_storage("jwt")
		JavaScript.eval("location.reload()")
	else:
		OS.shell_open("%s%s:%d/login?redirect=http://%s:8100" % ["https://" if API.use_ssl else "http://", API.adress, API.port, API.adress])
		var server = preload("res://components/shared/login_server.tscn").instance()
		add_child(server)
		server.connect("got_jwt", self, "_on_jwt")

func _on_jwt(jwt : String):
	JWT.set_token(jwt)
	start_connect()
