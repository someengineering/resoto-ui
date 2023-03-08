extends Node
class_name Utils

static func http_status_to_string(_status_code:int) -> String:
	var _status_messages:Array = [
		"Disconnected from the server.",
		"Currently resolving the hostname for the given URL into an IP.",
		"DNS failure: Can't resolve the hostname for the given URL.",
		"Currently connecting to server.",
		"Can't connect to the server.",
		"Connection established.",
		"Currently sending request.",
		"HTTP body received.",
		"Error in HTTP connection.",
		"Error in SSL handshake.",
	]
	return _status_messages[_status_code]


static func err_enum_to_string(_status_code:int) -> String:
	var _error_messages:Array = [
		"Ok.",
		"Generic error.",
		"Unavailable error.",
		"Unconfigured error.",
		"Unauthorized error.",
		"Parameter range error.",
		"Out of memory (OOM) error.",
		"File: Not found error.",
		"File: Bad drive error.",
		"File: Bad path error.",
		"File: No permission error.",
		"File: Already in use error.",
		"File: Can't open error.",
		"File: Can't write error.",
		"File: Can't read error.",
		"File: Unrecognized error.",
		"File: Corrupt error.",
		"File: Missing dependencies error.",
		"File: End of file (EOF) error.",
		"Can't open error.",
		"Can't create error.",
		"Query failed error.",
		"Already in use error.",
		"Locked error.",
		"Timeout error.",
		"Cannot connect.",
		"Cannot resolve.",
		"Connection error.",
		"Can't acquire resource error.",
		"Can't fork process error.",
		"Invalid data error.",
		"Invalid parameter error.",
		"Already exists error.",
		"Does not exist error.",
		"Database: Read error.",
		"Database: Write error.",
		"Compilation failed error.",
		"Method not found error.",
		"Linking failed error.",
		"Script failed error.",
		"Cycling link (import cycle) error.",
		"Invalid declaration error.",
		"Duplicate symbol error.",
		"Parse error.",
		"Busy error.",
		"Skip error.",
		"Help error.",
		"Bug error.",
		"Printer on fire error."]
	return _error_messages[_status_code]


static func truncate_string(_string:String, font:Font, _max_size:float=30.0) -> String:
	var truncated_text : String = ""
	var i : int = 0
	
	while font.get_string_size(truncated_text+"...  ").x < _max_size:
		if i >= _string.length():
			break
		truncated_text += _string[i]
		i += 1
	if truncated_text != _string:
		truncated_text += "..."
	return truncated_text


static func truncate_string_px(_string:String, letter_size:float, _max_size:float=30.0) -> String:
	var truncated_text : String = ""
	var i : int = 0
	
	while str(truncated_text+"...  ").length() * letter_size < _max_size:
		if i >= _string.length():
			break
		truncated_text += _string[i]
		i += 1
	if truncated_text != _string:
		truncated_text += "..."
	return truncated_text


static func print_dict(_dict:Dictionary, _depth:int) -> void:
	var _spacing : String = ""
	for i in _depth:
		_spacing += "  "
	for d in _dict.keys():
		prints(_spacing, d)
		if typeof(_dict[d]) == TYPE_DICTIONARY:
			print_dict(_dict[d], _depth+1)
		else:
			prints(_spacing + "  %s: %s" % [d, str(_dict[d])])


static func readable_dict(_dict:Dictionary, readable:String="", _depth:int=0) -> String:
	var _spacing : String = ""
	for i in _depth:
		_spacing += "  "
	
	for d in _dict.keys():
		if typeof(_dict[d]) == TYPE_DICTIONARY:
			readable += (_spacing + "%s:\n" % str(d))
			readable += readable_dict(_dict[d], "", _depth+1)
			
		elif typeof(_dict[d]) == TYPE_ARRAY:
			readable += (_spacing + "%s:\n" % str(d))
			readable += (readable_array(_dict[d], "", _depth+1))
			
		else:
			readable += (_spacing + "%s: %s\n" % [d, format_value(_dict[d])])
	return readable


static func slugify(string: String) -> String:
	var slug = string.to_lower().strip_edges().replace(" ", "-")
	var allowed_chars = "a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 -"
	var slugified_string := ""
	for c in slug:
		if allowed_chars.rsplit(" ").has(c):
			slugified_string += c
	slugified_string.trim_prefix("-").trim_suffix("-")
	return slugified_string


static func readable_array(_array:Array, readable:String="", _depth:int=0) -> String:
	var _spacing : String = ""
	for i in _depth:
		_spacing += "  "
	
	for array_element in _array:
		var next_text:= ""
		if typeof(array_element) == TYPE_DICTIONARY:
			next_text += ("%s" % readable_dict(array_element, "", _depth+1))
		elif typeof(array_element) == TYPE_ARRAY:
			next_text += ("%s" % readable_array(array_element, "", _depth+1))
		else:
			next_text += ("%s\n" % str(array_element))
		readable += _spacing + "- " + next_text.trim_prefix(_spacing + "  ")
	
	return readable


static func format_value(_value) -> String:
	if typeof(_value) == TYPE_STRING:
		return "'" + str(_value) + "'"
	else:
		return str(_value)


static func readable_date(_date:Dictionary) -> String:
	var month_names := ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
	return "{m} {d}, {y}".format({"m": month_names[_date.month - 1], "d": _date.day, "y": _date.year})


static func readable_duration(_dur:String) -> String:
	return _dur.replace("yr", "yr ").replace("mo", "mo ").replace("d", "d ").replace("h", "h ").replace("min", "min ")


static func comma_sep(number):
	var string : String = str(number)
	var mod : int = string.length() % 3
	var res : String = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res


static func set_path(dict, keypath, value):
	var current = keypath[0]
	if dict.has(current):
		if typeof(dict[current]) == TYPE_DICTIONARY:
			keypath.remove(0)
			set_path(dict[current],keypath, value)
			return true
		else:
			dict[current] = value
			return true
	else:
		print("Config variable not found")
		return false


static func load_json(path:String) -> Array:
	var file : File = File.new()
	if !file.file_exists(path):
		return []
	file.open(path, file.READ)
	var tmp_text : String = file.get_as_text()
	file.close()
	var data = parse_json(tmp_text)
	return data


static func load_json_dict(path:String) -> Dictionary:
	var file : File = File.new()
	if !file.file_exists(path):
		return {}
	file.open(path, file.READ)
	var tmp_text : String = file.get_as_text()
	file.close()
	var data = parse_json(tmp_text)
	return data


static func save_json(path:String, data):
	var file : File = File.new()
	file.open(path, file.WRITE)
	file.store_string(to_json(data))
	file.close()


static func save_string_to_json(path:String, string:String):
	var file : File = File.new()
	file.open(path, file.WRITE)
	file.store_string(string)
	file.close()
