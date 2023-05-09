extends Node

signal got_jwt

onready var _server =  TCP_Server.new()
var _clients := []
onready var regex = RegEx.new()


func _ready():
	_server.listen(8100)
	regex.compile("\\?code=([a-f\\d-]+)")


func _process(_delta: float) -> void:
	if _server:
		var new_client = _server.take_connection()
		if new_client:
			self._clients.append(new_client)
		for client in self._clients:
			if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				var bytes = client.get_available_bytes()
				if bytes > 0:
					var request_string = client.get_string(bytes)
					var found = regex.search(request_string).strings[0]
					client.put_data("HTTP/1.1 200 OK\nContent-Type: text/html\n\n<html><body>You can close this page!</body></html>".to_ascii())
					_server.stop()
					$HTTPRequest.request("http://localhost:8900/authorization/user"+found)


func _on_HTTPRequest_request_completed(_result, _response_code, headers, _body):
	for header in headers:
		if "Authorization" in header:
			var jwt = header.split(" ")[2]
			emit_signal("got_jwt", jwt)
			_g.popup_manager.popup_connect.visible = false
			queue_free()
