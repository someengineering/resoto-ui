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


const default_graph:String = "resoto"
const default_section:String = "reported"

var default_options:Options = Options.new()
var accept_json_headers:Headers = Headers.new()
var accept_json_put_headers:Headers = Headers.new()
var config_put_headers:Headers = Headers.new()
var accept_json_nd_headers:Headers = Headers.new()
var accept_text_headers:Headers = Headers.new()
var content_urlencoded_headers:Headers = Headers.new()
var content_json_headers : Headers = Headers.new()


func _init().(default_options) -> void:
	accept_text_headers.Accept = "text/plain"
	content_urlencoded_headers.Content_Type = "Application/x-www-form-urlencoded"
	content_json_headers.Content_Type = "application/json"
	content_json_headers.Accept = "*/*"


func _transform_json(error:int, response:ResotoAPI.Response) -> void:
	if error != OK:
		handle_bad_response_codes(response.response_code)
		return
	
	var string_to_parse:String = response.body.get_string_from_utf8()
	if string_to_parse != "":
		var json_result:JSONParseResult = JSON.parse(string_to_parse)
		if json_result.error == OK:
			response.transformed["result"] = json_result.result
			return
	
	response.transformed["result"] = string_to_parse


func handle_bad_response_codes(_response_code:int):
	match _response_code:
		401:
			_g.emit_signal("add_toast", "401: Unauthorized", "[b][url=reconnect]Check your connection settings.[/url][/b]", 1, self, -1)
#		400:
			# Bad Requests should be handled by components / widgets as it can
			# Be caused by a lot of different problems
#			_g.emit_signal("add_toast", "400: Bad Request", "", 3, self, 3)


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
	else:
		handle_bad_response_codes(response.response_code)


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
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_text_headers)
	request.connect("pre_done", self, "_transform_string")
	return request


func post_cli_execute_json(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func post_cli_execute_streamed(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_text_headers)
	request.connect("pre_data", self, "_transform_string_chunk")
	return request


func post_cli_execute_nd_chunks(body:String, graph:String=default_graph) -> ResotoAPI.Request:
	var path: String = "/cli/execute?graph=" + graph
	var request = req_post(path, body, accept_json_headers)
	request.connect("pre_data", self, "_transform_nd_json")
	return request


func post_graph_search(body:String, type:String="graph", 
	graph:String=default_graph,
	section:String=default_section) -> ResotoAPI.Request:
	var request = req_post("/graph/"+ graph +"/search/"+ type + "?section=%s" % section, body, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_node_by_id(node_id:String, graph:String=default_graph) -> ResotoAPI.Request:
	var request = req_get("/graph/"+ graph +"/node/" + node_id, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_cli_info() -> ResotoAPI.Request:
	var request = req_get("/cli/info", accept_text_headers)
	request.connect("pre_done", self, "_transform_string")
	return request


func get_system_ready() -> ResotoAPI.Request:
	var request = req_get("/system/ready", accept_text_headers)
	request.connect("pre_done", self, "_transform_string")
	return request


func get_model() -> ResotoAPI.Request:
	var request = req_get("/model", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_model_flat() -> ResotoAPI.Request:
	var request = req_get("/model?flat=true", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_config_model() -> ResotoAPI.Request:
	var request = req_get("/configs/model", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_configs() -> ResotoAPI.Request:
	var request = req_get("/configs", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_config_id(_config_id:String="resoto.core", separate_overrides:bool=false) -> ResotoAPI.Request:
	var config_id = "/config/" + _config_id + "?separate_overrides=%s&apply_overrides=true" % str(separate_overrides)
	var request = req_get(config_id, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func put_config_id(_config_id:String="resoto.core", _config_body:String="", _dry_run:bool=false) -> ResotoAPI.Request:
	var dry_run_mode = "" if not _dry_run else "?dry_run=true"
	var config_id = "/config/" + _config_id + dry_run_mode
	var request = req_put(config_id, _config_body, config_put_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func patch_config_id(_config_id:String="resoto.core", _config_body:String="") -> ResotoAPI.Request:
	var config_id = "/config/" + _config_id
	var request = req_patch(config_id, _config_body, accept_json_put_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func delete_config_id(_config_id:String="", _config_body:String="") -> ResotoAPI.Request:
	var config_id = "/config/" + _config_id
	var request = req_delete(config_id, _config_body, accept_json_put_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_subscribers() -> ResotoAPI.Request:
	var request = req_get("/subscribers", accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_infra_info() -> ResotoAPI.Request:
	var request = req_post("/graph/"+ default_graph +"/search/graph?section=reported", 
							"is(cloud) -[0:2]-> is(cloud, account, region)",
							 accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func query_tsdb(_query:String):
	var body = "query=" + _query
	var request = req_get("/tsdb/api/v1/query?"+body, content_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func query_range_tsdb(_query:String, start_ts:int=1656422693, end_ts:int=1657025493, step:int=3600):
	var body = "query=" + _query + "&start=%d&end=%d&step=%d" % [start_ts, end_ts, step]
	var request = req_get("/tsdb/api/v1/query_range?"+body, content_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request
	
	
func tsdb_label_values(label:String):
	var request = req_get("/tsdb/api/v1/label/%s/values"%label, content_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func analytics(body : String):
	var request = req_post("/analytics", body, content_json_headers)
	return request


func ping():
	var request = req_get("/system/ping", accept_text_headers)
	return request

func get_benchmark_report(benchmark : String, accounts : String):
	var query = "/report/benchmark/%s/graph/%s" % [benchmark, default_graph]
	if accounts != "":
		query += "?accounts=%s" % accounts.percent_encode()
	var request = req_get(query, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request


func get_check_resources(check_id : String, account_id : String):
	var query = "/report/check/%s/graph/%s" % [check_id, default_graph]
	if account_id != "":
		query += "?accounts=%s" % account_id
	var request = req_get(query, accept_json_headers)
	request.connect("pre_done", self, "_transform_json")
	return request
