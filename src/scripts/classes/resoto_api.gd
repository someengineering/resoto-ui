extends UserAgent
class_name ResotoAPI

class Options extends UserAgent.Options:
	func _init() -> void:
		host = "127.0.0.1"
		port = 8900
		use_ssl = false

class Headers extends UserAgent.RequestHeaders:
	var Resoto_Shell_Terminal = true
	var Resoto_Shell_Columns = 80
	var Resoto_Shell_Rows = 40
	var User_Agent = "resoto UI"
	var Color_System = "monochrome"
	var Content_Type = "text/plain"
	var Accept = "application/x-ndjson" # application/x-ndjson
	var Accept_Encoding = ""
	var Resotoui_via = ""
	var Authorization = ""

var default_graph:String = "resoto"
var default_options:Options = Options.new()
var accept_json_headers:Headers = Headers.new()
var accept_text_headers:Headers = Headers.new()


func _init().(default_options) -> void:
	accept_text_headers.Accept = "text/plain"


func refresh_jwt_header(header:Headers) -> void:
	if JWT.token == "" or JWT.token_expired():
		JWT.create_jwt("")
	header.Authorization = "Bearer " + JWT.token


func _transform_json(error:int, response:ResotoAPI.Response) -> void:
	if error == OK:
		response.transformed["result"] = parse_json(response.body.get_string_from_utf8())


func _transform_nd_json(_chunk:PoolByteArray, response:ResotoAPI.Response, request:ResotoAPI.Request) -> void:
	var parsed_chunk:Chunk = parse_chunk(_chunk)
	if parsed_chunk.error == 0:
		if response.transformed.has("result"):
			response.transformed["result"].append(parsed_chunk.result)
		else:
			response.transformed["result"] = [parsed_chunk.result]
		request.emit_signal("data", parsed_chunk.result)


func _transform_string_chunk(_chunk:PoolByteArray, _response:ResotoAPI.Response, request:ResotoAPI.Request) -> void:
	request.emit_signal("data", _chunk.get_string_from_utf8())


func _transform_string(error:int, response:ResotoAPI.Response) -> void:
	if error == OK:
		response.transformed["result"] = response.body.get_string_from_utf8()


class Chunk:
	var error: int
	var result: Dictionary


static func parse_chunk( _chunk:PoolByteArray ) -> Chunk:
	var resulting_chunk = Chunk.new()
	var chunk:String = _chunk.get_string_from_ascii()
	if ["", "[", "\n]", ",\n"].has(chunk) or chunk.begins_with("Error:"):
		if chunk.begins_with("Error:"):
			resulting_chunk.error = FAILED
		resulting_chunk.error = ERR_SKIP
	
	var splitted_chunk = chunk.split("\n", false)
	
	if splitted_chunk.empty():
		resulting_chunk.error = ERR_SKIP
	
	for element in splitted_chunk:
		var parse_result : JSONParseResult = JSON.parse( element )
		if parse_result.error == OK:
			if typeof(parse_result.result) == TYPE_DICTIONARY:
				resulting_chunk.error = OK
				resulting_chunk.result = parse_result.result
		else:
			resulting_chunk.error = FAILED
			
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
	refresh_jwt_header(accept_json_headers)
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


func get_subscribers() -> ResotoAPI.Request:
	refresh_jwt_header(accept_json_headers)
	var request = req_get("/subscribers", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request
