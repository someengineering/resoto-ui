extends Node

const DEFAULT_PSK: String = "changeme"

var _req_res: ResotoAPI.Request
var _resoto_api: ResotoAPI = ResotoAPI.new()

var adress: String = "http://127.0.0.1" setget set_adress
var port: int = 8900 setget set_port
var psk: String = DEFAULT_PSK setget set_psk
var graph_id: String = "resoto"


func _ready() -> void:
	_resoto_api.accept_json_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	_resoto_api.accept_text_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	_resoto_api.accept_json_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"
	_resoto_api.accept_text_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"#
	
	Engine.get_main_loop().connect("idle_frame", self, "poll")


func poll() -> void:
	_resoto_api.poll()


func set_adress(_new_adress:String) -> void:
	adress = _new_adress
	connection_config()


func set_port(_new_port:int) -> void:
	port = _new_port
	connection_config()


func set_psk(_new_psk:String) -> void:
	psk = _new_psk
	connection_config()


func connection_config(_adress:String = adress, _port:int = port, _psk:String = psk) -> void:
	adress = _adress
	port = _port
	psk = _psk
	JWT.psk = _psk
	_resoto_api.options.host = adress
	_resoto_api.options.port = port


func cli_info(_connect_to:Node) -> void:
	_req_res = _resoto_api.get_cli_info()
	_req_res.connect("done", _connect_to, "_on_cli_info_done")


func cli_execute(_command:String, _connect_to:Node) ->ResotoAPI.Request:
	_req_res = _resoto_api.post_cli_execute(_command, graph_id)
	_req_res.connect("done", _connect_to, "_on_cli_execute_done")
	return _req_res


func get_model(_connect_to:Node) -> void:
	_req_res = _resoto_api.get_model()
	_req_res.connect("done", _connect_to, "_on_get_model_done")


func cli_execute_json(_command:String, _connect_to:Node) -> void:
	_req_res = _resoto_api.post_cli_execute_nd_chunks(_command, graph_id)
	_req_res.connect("data", _connect_to, "_on_cli_execute_json_data")
	_req_res.connect("done", _connect_to, "_on_cli_execute_json_done")
