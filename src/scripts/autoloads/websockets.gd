extends Node

var ws : WebSocketClient = null
var ws_header : PoolStringArray = []
var auto_reconnect := true

func _ready():
	ws = WebSocketClient.new()
	ws.verify_ssl = false
	_g.connect("connected_to_resotocore", self, "connect_websockets")


func refresh_jwt_header() -> void:
	if JWT.token == "" or JWT.token_expired():
		JWT.create_jwt("")
	ws_header = ["Authorization: Bearer %s" % JWT.token]


func refresh_auth_cookie() -> void:
	if JWT.token == "" or JWT.token_expired():
		JWT.create_jwt("")
	
	var cookie_content : String = "\"resoto_authorization=\\\"Bearer %s\\\"; path=/events\"" % JWT.token
	JavaScript.eval("setCookie(%s)" % cookie_content)


func _process(_delta):
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()


func _exit_tree():
	ws.disconnect_from_host()


func connect_websockets():
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		return
	
	# Connect signals
	if not ws.is_connected("connection_established", self, "_connection_established"):
		ws.connect("connection_established", self, "_connection_established")
	if not ws.is_connected("connection_closed", self, "_connection_closed"):
		ws.connect("connection_closed", self, "_connection_closed")
	if not ws.is_connected("connection_error", self, "_connection_error"):
		ws.connect("connection_error", self, "_connection_error")
	if not ws.is_connected("data_received", self, "_on_data"):
		ws.connect("data_received", self, "_on_data")
	
	var ws_url = "ws://%s:%s/events" if not API.use_ssl else "wss://%s:%s/events"
	ws_url = ws_url % [API.adress, API.port]
	
	var err : int
	if OS.has_feature("HTML5"):
		refresh_auth_cookie()
		print("Websocket (HTML5): Connecting to " + ws_url)
		err = ws.connect_to_url(ws_url)
	else:
		refresh_jwt_header()
		print("Websocket (Native): Connecting to " + ws_url)
		err = ws.connect_to_url(ws_url, [], false, ws_header)
	
	if err != OK:
		print("Websocket: Unable to connect")
		set_process(false)


func _connection_closed(_error):
	print("Websocket: Connection closed")
	print(_error)
	set_process(false)
	if auto_reconnect:
		connect_websockets()


func _connection_error():
	print("Websocket: Connection error")
	set_process(false)


func _connection_established(protocol):
	print("Websocket: Connection established.")
	ws.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	if protocol != "":
		print("Websocket: Protocol: " + protocol)


func _on_data():
	_g.emit_signal("websocket_message", ws.get_peer(1).get_packet().get_string_from_utf8())
	# for debug
#	print("Got data from server: ", ws.get_peer(1).get_packet().get_string_from_utf8())


func test_websocket():
	if ws.get_peer(1).is_connected_to_host():
		var test_string : String = JSON.print("")
		ws.get_peer(1).put_packet(test_string.to_utf8())
