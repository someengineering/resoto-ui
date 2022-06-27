extends UserAgent
class_name ResotoAPI

class Options extends UserAgent.Options:
	func _init() -> void:
		host = "127.0.0.1"
		port = 8900
		use_ssl = false

class Headers extends UserAgent.RequestHeaders:
	var Resoto_Shell_Terminal = true
	var Resoto_Shell_Columns = 100
	var Resoto_Shell_Rows = 40
	var User_Agent = "resoto UI"
	var Color_System = "monochrome"
	var Content_Type = "text/plain"
	var Accept = "application/json"
	var Accept_Encoding = ""
	var Resotoui_via = ""
	var Authorization = ""


var default_graph:String = "resoto"
var default_options:Options = Options.new()
var accept_json_headers:Headers = Headers.new()
var accept_json_put_headers:Headers = Headers.new()
var config_put_headers:Headers = Headers.new()
var accept_json_nd_headers:Headers = Headers.new()
var accept_text_headers:Headers = Headers.new()
var content_json_headers:Headers = Headers.new()
var content_ndjson_headers:Headers = Headers.new()


func _init().(default_options) -> void:
	accept_text_headers.Accept = "text/plain"
	content_json_headers.Content_Type = "application/json"
	content_ndjson_headers.Content_Type = "application/x-ndjson"


func refresh_jwt_header(header:Headers) -> void:
	if JWT.token == "" or JWT.token_expired():
		JWT.create_jwt("")
	header.Authorization = "Bearer " + JWT.token


func _transform_json(error:int, response:ResotoAPI.Response) -> void:
	if error == OK:
		var string_to_parse:String = response.body.get_string_from_utf8()
		if not string_to_parse.begins_with("Error"):
			var json_result:JSONParseResult = JSON.parse(string_to_parse)
			if json_result.error == OK:
				response.transformed["result"] = json_result.result
				return

		response.transformed["result"] = string_to_parse


func _transform_nd_json(_chunk:PoolByteArray, response:ResotoAPI.Response, request:ResotoAPI.Request) -> void:
	var full_chunk : PoolByteArray = []
	full_chunk = response.chunk_reminder
	full_chunk.append_array(_chunk)
	
	var parsed_chunk:Chunk = parse_chunk(full_chunk)
	if parsed_chunk.error == 0:
		if response.transformed.has("result"):
			response.transformed["result"].append_array(parsed_chunk.result)
			response.transformed["strings"].append_array(parsed_chunk.result_string)
		else:
			response.transformed["result"] = parsed_chunk.result
			response.transformed["strings"] = parsed_chunk.result_string
	
	response.chunk_reminder = parsed_chunk.reminder
		
	if parsed_chunk.result.size() > 0:
		request.emit_signal("data", parsed_chunk.result_string)


func _transform_string_chunk(_chunk:PoolByteArray, _response:ResotoAPI.Response, request:ResotoAPI.Request) -> void:
	request.emit_signal("data", _chunk.get_string_from_utf8())


func _transform_string(error:int, response:ResotoAPI.Response) -> void:
	if error == OK:
		response.transformed["result"] = response.body.get_string_from_utf8()


class Chunk:
	var error: int
	var result: Array
	var result_string : PoolStringArray = []
	var reminder: PoolByteArray = []


static func parse_chunk( _chunk:PoolByteArray ) -> Chunk:
	var resulting_chunk = Chunk.new()
	resulting_chunk.result = []
	resulting_chunk.result_string = []
	resulting_chunk.reminder = []
	var chunk:String = _chunk.get_string_from_ascii()
	if ["", "[", "]\n", "[\n", "\n]", ",\n"].has(chunk) or chunk.begins_with("Error:"):
		if chunk.begins_with("Error:"):
			resulting_chunk.error = FAILED
		resulting_chunk.error = ERR_SKIP
		return resulting_chunk
	
	var splitted_chunk = chunk.split("\n", false)
	
	if splitted_chunk.empty():
		resulting_chunk.error = ERR_SKIP
		
	if not chunk.ends_with("\n"):
		resulting_chunk.reminder = splitted_chunk[splitted_chunk.size()-1].to_ascii()
		splitted_chunk.remove(splitted_chunk.size()-1)
	
	var aux_string_array : PoolStringArray = []
	
	for element in splitted_chunk:
		if ["", "[", "]", ","].has(element):
			continue
		var parse_result : JSONParseResult = JSON.parse( element )
		if parse_result.error == OK:
			if typeof(parse_result.result) == TYPE_DICTIONARY:
				resulting_chunk.error = OK
				resulting_chunk.result.append(parse_result.result)
				aux_string_array.append(element)
		else:
			resulting_chunk.error = FAILED
	
	resulting_chunk.result_string = aux_string_array
	return resulting_chunk


func post_cli_execute(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	refresh_jwt_header(accept_text_headers)
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_text_headers)
	request.connect("pre_done", self, "_transform_string")
	return request


func post_cli_execute_streamed(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	refresh_jwt_header(accept_text_headers)
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_text_headers)
	request.connect("pre_data", self, "_transform_string_chunk")
	return request


func post_cli_execute_nd_chunks(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_nd_headers)
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_json_headers)
	request.connect("pre_data", self, "_transform_nd_json")
	return request


func get_cli_info() -> ResotoAPI.Request:
	refresh_jwt_header(accept_text_headers)
	var request = req_get("/cli/info", accept_text_headers)
	request.connect("pre_done", self, "_transform_string")
	return request


func get_model() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/model", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func patch_model(body : String) -> ResotoAPI.Request:
	refresh_jwt_header(content_json_headers)
	var request = req_patch("/model", body, content_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request

func get_config_model() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/configs/model", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_configs() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/configs", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_config_id(_config_id:String="resoto.core") -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var config_id = "/config/" + _config_id
	var request = req_get(config_id, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_graph() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/graph", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request

func put_config_id(_config_id:String="resoto.core", _config_body:String="") -> ResotoAPI.Request:
	refresh_jwt_header(config_put_headers)
	var config_id = "/config/" + _config_id
	var request = req_put(config_id, _config_body, config_put_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func merge_graph(graph_root:String, body:String) -> ResotoAPI.Request:
	refresh_jwt_header(content_ndjson_headers)
	var request = req_post("/graph/%s/merge" % graph_root, body, content_ndjson_headers)
	request.connect("pre_done", self, "_transform_json")
	return request
	
func get_full_graph(graph_root:String, body:String) -> ResotoAPI.Request:
	var headers = Headers.new()
	headers.Accept = "Application/x-ndjson"
	headers.Content_Type = "text/plain"
	refresh_jwt_header(content_ndjson_headers)
	var request = req_post("/graph/%s/search/graph" % graph_root, body, content_ndjson_headers)
	
	return request


func get_subscribers() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/subscribers", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request
