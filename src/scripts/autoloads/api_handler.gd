extends Node

const DEFAULT_PSK: String = "changeme"

var _req_res: ResotoAPI.Request
var _resoto_api: ResotoAPI = ResotoAPI.new()

var adress: String		= "http://127.0.0.1" setget set_adress
var port: int			= 8900 setget set_port
var psk: String			= DEFAULT_PSK setget set_psk
var graph_id: String	= "resoto"
var use_ssl: bool		= false setget set_use_ssl


func _ready() -> void:
	_resoto_api.accept_json_nd_headers.Accept = "application/x-ndjson"
	_resoto_api.accept_json_put_headers.Content_Type = "application/json"
	_resoto_api.accept_json_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	_resoto_api.accept_text_headers.Accept_Encoding = "gzip" if OS.has_feature("web") else ""
	_resoto_api.accept_json_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"
	_resoto_api.accept_text_headers.Resotoui_via = "Web" if OS.has_feature("web") else "Desktop"
	_resoto_api.config_put_headers.Accept = "application/json"
	_resoto_api.config_put_headers.Content_Type = "application/json"
	
	Engine.get_main_loop().connect("idle_frame", self, "poll")


func poll() -> void:
	_resoto_api.poll()


func set_adress(_new_adress:String) -> void:
	adress = _new_adress
	connection_config()


func set_use_ssl(_use_ssl:bool) -> void:
	use_ssl = _use_ssl
	connection_config()


func set_port(_new_port:int) -> void:
	port = _new_port
	connection_config()


func set_psk(_new_psk:String) -> void:
	psk = _new_psk
	connection_config()


func connection_config(_adress:String = adress, _port:int = port, _psk:String = psk, _use_ssl:bool = use_ssl) -> void:
	adress = _adress
	port = _port
	psk = _psk
	use_ssl = _use_ssl
	JWT.psk = _psk
	_resoto_api.options.host = adress
	_resoto_api.options.port = port
	_resoto_api.options.use_ssl = use_ssl
	# For debug purposes
	prints("Resoto UI: Connection Settings to Core | Host:", adress, "- Port:", port, "- SSL:", use_ssl)

func get_model(_connect_to:Node, _connect_function:String="_on_get_model_done") -> void:
	_req_res = _resoto_api.get_model()
	_req_res.connect("done", _connect_to, _connect_function)


func patch_model(_body:String, _connect_to:Node, _connect_function:String="_on_patch_model_done") -> void:
	_req_res = _resoto_api.patch_model(_body)
	_req_res.connect("done", _connect_to, _connect_function)


func get_configs(_connect_to:Node, _connect_function:String="_on_get_configs_done"):
	_req_res = _resoto_api.get_configs()
	_req_res.connect("done", _connect_to, _connect_function)


func get_config_id(_connect_to:Node, _config_id:String="resoto.core",
	_connect_function:String="_on_get_config_id_done"):
	_req_res = _resoto_api.get_config_id(_config_id)
	_req_res.connect("done", _connect_to, _connect_function, [_config_id])


func put_config_id(_connect_to:Node, _config_id:String="resoto.core",
	_config_body:String="", _connect_function:String="_on_put_config_id_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.put_config_id(_config_id, _config_body)
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res

func patch_config_id(_connect_to:Node, _config_id:String="resoto.core",
	_config_body:String="", _connect_function:String="_on_patch_config_id_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.patch_config_id(_config_id, _config_body)
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res

func delete_config_id(_connect_to:Node, _config_id:String="",
	_connect_function:String="_on_delete_config_id_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.delete_config_id(_config_id, "")
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res

func get_config_model(_connect_to:Node, _connect_function:String="_on_get_config_model_done") -> void:
	_req_res = _resoto_api.get_config_model()
	_req_res.connect("done", _connect_to, _connect_function)
	

func query_tsdb(_query:String, _connect_to:Node, _connect_function:String="_on_query_tsdb_done") -> void:
	_req_res = _resoto_api.query_tsdb(_query)
	_req_res.connect("done", _connect_to, _connect_function)


func query_range_tsdb(_query:String, _connect_to:Node, start_ts:int=1656422693,
	end_ts:int=1657025493, step:int=3600, _connect_function:String="_on_query_range_tsdb_done"):
	_req_res = _resoto_api.query_range_tsdb(_query, start_ts, end_ts, step)
	_req_res.connect("done", _connect_to, _connect_function)


func tsdb_label_values(_label:String, _connect_to:Node, _connect_function:String="_on_tsdb_label_values_done"):
	_req_res = _resoto_api.tsdb_label_values(_label)
	_req_res.connect("done", _connect_to, _connect_function)


func system_ready(_connect_to:Node, _connect_function:String="_on_system_ready_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.get_system_ready()
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res


func cli_info(_connect_to:Node, _connect_function:String="_on_cli_info_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.get_cli_info()
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res


func cli_execute(_command:String, _connect_to:Node,
	_connect_function:String="_on_cli_execute_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.post_cli_execute(_command, graph_id)
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res


func cli_execute_streamed(_command:String, _connect_to:Node,
	_connect_data_function:String="_on_cli_execute_streamed_data",
	_connect_done_function:String="_on_cli_execute_streamed_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.post_cli_execute_streamed(_command, graph_id)
	_req_res.connect("data", _connect_to, _connect_data_function)
	_req_res.connect("done", _connect_to, _connect_done_function)
	return _req_res


func cli_execute_json(_command:String, _connect_to:Node,
	_connect_data_function:String="_on_cli_execute_json_data",
	_connect_done_function:String="_on_cli_execute_json_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.post_cli_execute_nd_chunks(_command, graph_id)
	_req_res.connect("data", _connect_to, _connect_data_function)
	_req_res.connect("done", _connect_to, _connect_done_function)
	return _req_res


func graph_search(_command:String, _connect_to:Node, type:String="graph",
	_connect_function:String="_on_graph_search_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.post_graph_search(_command, type, graph_id)
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res


func _get_infra_info(_connect_to:Node = self,
	_connect_function:String="_on_get_infra_info_done") -> void:
	_req_res = _resoto_api.get_infra_info()
	_req_res.connect("done", _connect_to, _connect_function)
	

func aggregate_search(_query:String, _connect_to:Node,
	_connect_function:String="_on_aggregate_search_done") -> ResotoAPI.Request:
	_req_res = _resoto_api.aggregate_search(_query)
	_req_res.connect("done", _connect_to, _connect_function)
	return _req_res


func _get_infra_info(_connect_to:Node = self) -> void:
	_req_res = _resoto_api.get_infra_info()
	_req_res.connect("done", _connect_to, "_on_get_infra_info_done")
	

func aggregate_search(_query : String, _connect_to: Node) -> ResotoAPI.Request:
	_req_res = _resoto_api.aggregate_search(_query)
	_req_res.connect("done", _connect_to, "_on_aggregate_search_done")
	return _req_res
	
func search_graph(_query : String, _connect_to: Node) -> ResotoAPI.Request:
	_req_res = _resoto_api.search_graph(_query)
	_req_res.connect("done", _connect_to, "_on_search_graph_done")
	return _req_res
