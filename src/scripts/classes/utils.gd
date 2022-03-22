extends Node
class_name Utils

static func http_status_to_string(_status_code:int) -> String:
	var _status_messages:Array = [
		"Status: Disconnected from the server.",
		"Status: Currently resolving the hostname for the given URL into an IP.",
		"Status: DNS failure: Can't resolve the hostname for the given URL.",
		"Status: Currently connecting to server.",
		"Status: Can't connect to the server.",
		"Status: Connection established.",
		"Status: Currently sending request.",
		"Status: HTTP body received.",
		"Status: Error in HTTP connection.",
		"Status: Error in SSL handshake.",
	]
	return _status_messages[_status_code]
