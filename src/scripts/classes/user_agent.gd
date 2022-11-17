extends Reference
class_name UserAgent

var debug_messages: bool = false
var options: Options
var cookies_: Dictionary = {}
var requests_: Array     = []


class Options:
	var host: String  = ""
	var port: int     = 80
	var use_ssl: bool = false


class RequestHeaders:
	pass


class Response:
	var status_code:int
	var response_code:int
	var headers:Dictionary
	var body:PoolByteArray
	var transformed:Dictionary
	
	func to_string() -> String:
		if not body:
			return ""
		return body.get_string_from_utf8()


class Request:
	enum states {CHECK_CONNECTION, CONNECTING, CONNECTED, REQUESTING, BODY, RECEIVE, RECEIVED, DONE, RESPONSE, RESPONSE_READY}
	
	signal pre_done(error, response)
	signal done(error, response)
	signal pre_data(chunk, response)
	signal data(chunk, response, request)
	
	var state_:int = states.CHECK_CONNECTION
	var http_:HTTPClient
	var response_:Response
	var response_chunks:PoolByteArray = []
	var chunk_idx:int = 0
	var chunks_resizes:int = 0
	
	var method:int
	var path:String
	var headers:Array = []
	var body:String = ""
	
	func _init(_method:int, _path:String, _headers:Array, _body:String) -> void:
		method = _method
		path = _path
		headers = _headers
		body = _body
	
	
	func cancel(err_code:int=1) -> void:
		emit_signal("done", err_code, null)
		state_ = states.DONE
	
	
	func abort() -> void:
		state_ = states.RESPONSE_READY
	

	func poll_() ->bool:
		var err : int = http_.poll()
		if err != OK:
			emit_signal("done", err, null)
			state_ = states.DONE
			return false
		return true
	
	func request_(_method:int = method, _path:String = path, _headers:Array = headers, _body:String = body) -> void:
		var http_status:int= http_.get_status()
		
		if false:
			print("######## HEADERS ########")
			for i in _headers:
				print(i)
		
		match state_:
			states.CHECK_CONNECTION:
				if false:
					prints(_method, _path, _body)
				if http_status == HTTPClient.STATUS_CONNECTING or http_status == HTTPClient.STATUS_RESOLVING:
					if not poll_():
						return
					else:
						
						state_ = states.CONNECTING
			
			states.CONNECTING:
				if http_status != HTTPClient.STATUS_CONNECTED:
					if not poll_():
						return
					elif http_status == HTTPClient.STATUS_CONNECTION_ERROR or http_status == HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
						emit_signal("done", -1, null)
						state_ = states.DONE
				elif http_status == HTTPClient.STATUS_CONNECTED:
					state_ = states.CONNECTED
			
			states.CONNECTED:
				var err : int = http_.request(method, path, headers, body)
				if err != OK:
					emit_signal("done", err, null)
					state_ = states.DONE
				else:
					state_ = states.REQUESTING
			
			states.REQUESTING:
				if http_status == HTTPClient.STATUS_REQUESTING:
					if not poll_():
						return

				elif http_status == HTTPClient.STATUS_BODY or http_status == HTTPClient.STATUS_CONNECTED:
					state_ = states.RECEIVE
			
			states.RECEIVE:
				if http_status != HTTPClient.STATUS_BODY and http_status != HTTPClient.STATUS_CONNECTED:
					emit_signal("done", -1, null)
					state_ = states.DONE
				else:
					state_ = states.RECEIVED
			
			states.RECEIVED:
				if not http_.has_response():
					emit_signal("done", -1, null)
					state_ = states.DONE
				else:
					response_				= Response.new()
					response_.response_code	= http_.get_response_code()
					response_.status_code	= http_status
					response_.headers		= http_.get_response_headers_as_dictionary()
					response_.body			= PoolByteArray()
					state_ = states.RESPONSE
			
			states.RESPONSE:
				for i in 100:
					if http_.get_status() == HTTPClient.STATUS_BODY:
						if not poll_():
							return
						
						var chunk : PoolByteArray = http_.read_response_body_chunk()
						if chunk.size() != 0:
							emit_signal("pre_data", chunk, response_, self)
							while response_chunks.size() <= chunk_idx + chunk.size():
								response_chunks.resize(int(pow(2,chunks_resizes)))
								chunks_resizes += 1
							for byte in chunk:
								response_chunks[chunk_idx] = byte
								chunk_idx += 1
					else:
						state_ = states.RESPONSE_READY
						break
			
			states.RESPONSE_READY:
				response_chunks.resize(chunk_idx)
				response_.body = response_chunks
				if [401, 400].has(response_.response_code):
					emit_signal("pre_done", FAILED, response_)
					emit_signal("done", FAILED, response_)
				else:
					emit_signal("pre_done", OK, response_)
					emit_signal("done", OK, response_)
				state_ = states.DONE


func _init(_options:Options) -> void:
	self.options = _options


func _on_request_done_(_err:int, _response:Response) -> void:
	# look for a set cookie in headers and set in cookies_
	pass


func request_(method:int, path:String, headers:Array = [], body:String = "") -> Request:
	var http_ :HTTPClient = HTTPClient.new()
	var err : int = http_.connect_to_host(options.host, options.port, options.use_ssl)
	if err != OK:
		debug_message("Error in connection! Check adress and port!")
		return null
	
	var req:Request = Request.new(method, path, headers, body)
	req.http_		= http_
	
	requests_.push_back(req)
	req.connect("done", self, "_on_request_done_")
	
	return req


func create_headers(headers:RequestHeaders) ->Array:
	var new_headers: Array = []
	var properties : Array = headers.get_property_list()
	
	for property in properties:
		if property.usage == 8192:
			new_headers.append(property.name.replace("_", "-") + ": " + str(headers.get(property.name)))
	return new_headers


func req_get(path:String, req_headers:RequestHeaders) -> Request:
	return request_(HTTPClient.METHOD_GET, path, create_headers(req_headers))


func req_post(path:String, body:String, req_headers:RequestHeaders) -> Request:
	return request_(HTTPClient.METHOD_POST, path, create_headers(req_headers), body)


func req_put(path:String, body:String, req_headers:RequestHeaders) -> Request:
	return request_(HTTPClient.METHOD_PUT, path, create_headers(req_headers), body)


func req_patch(path:String, body:String, req_headers:RequestHeaders) -> Request:
	return request_(HTTPClient.METHOD_PATCH, path, create_headers(req_headers), body)


func req_delete(path:String, body:String, req_headers:RequestHeaders) -> Request:
	return request_(HTTPClient.METHOD_DELETE, path, create_headers(req_headers), body)


func poll() -> void:
	var requests: Array = requests_
	requests_           = []
	
	for request in requests:
		if request.state_ != request.states.DONE:
			request.request_()
			requests_.push_back(request)


func debug_message(_msg:String, _detail:int = 0) -> void:
	if !debug_messages:
		return
	print(_msg)
