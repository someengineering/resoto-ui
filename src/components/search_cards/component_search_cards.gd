extends Control


enum SimpleKind {s_string, s_int, duration, datetime}

var all_kinds := {}
var complex_kinds := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: load model and provide kinds / 
	var request = API.get_model(self)
	pass # Replace with function body.

func prop_path(model: Dictionary, property: Dictionary):
	var kind = property["kind"]
	var name = property["name"]
	if kind.endswith("[]"):
		kind = kind.substr(0, kind.length() - 2)
		name += "[*]"	
	var model_kind = model.get(name)
	if model_kind != null and kind.get("properties") != null:
		pass		
		
class Property:
	var name: String
	var kind: String

	func _init(_name: String, _kind: String):
		name = _name
		kind = _kind

class Kind:
	var fqn: String
	var runtime_kind
	var properties: Array # Array[Property]
	var bases: Array # Array[String]
	var aggregate_root: bool = true
	
	func _init(_fqn: String, _runtime_kind, _properties: Array, _bases: Array, _aggregate_root: bool):
		fqn = _fqn
		runtime_kind = _runtime_kind
		properties = _properties
		bases = _bases
		aggregate_root = _aggregate_root

class ComplexRoots:
	var fqn: String
	var properties: Array # Array[Property]
	var bases: Array # Array[String]
	
	func _init(_fqn: String, _properties: Array, _bases: Array):
		fqn = _fqn
		properties = _properties
		bases = _bases


	static func sort_alphabetical(left, right) -> bool:
		return left[0] < right[0]
		
	static func sort_match(left, right) -> bool:
		var l_re:RegExMatch = left[1]
		var r_re:RegExMatch = right[1]
		var l_start = l_re.get_start()
		var l_end = l_re.get_end(1)
		var r_start = l_re.get_start()
		var r_end = l_re.get_end(1)
		if l_start < r_start:
			return true
		elif l_start > r_start:
			return false
		else:
			if l_end > r_end:
				return true
			elif l_end < r_end:
				return false			
			else:
				return left[0]<right[0]
		
func load_model(json: Array) -> Dictionary:
	var kinds := {}
	for m in json:
		var props = []
		for p in m.get("properties", []):
			props.append(Property.new(p.get("name"), p.get("kind")))
		var kind = Kind.new(m.get("fqn"), m.get("runtime_kind"), props, m.get("bases", []), m.get("aggregate_root", false))
		kinds[kind.fqn] = kind
	return kinds

func complex_roots(kinds: Dictionary) -> Dictionary:
	var roots := {}
	for kind in kinds.values():
		if kind.aggregate_root:
			var props = kind.properties.duplicate()
			for base in kind.bases:
				props.append_array(kinds[base].properties)
			roots[kind.fqn] = ComplexRoots.new(kind.fqn, props, kind.bases)
	return roots
			

func regexp_from(name) -> RegEx:
	var result = RegEx.new()
	if name == null:
		result.compile(".*")
	else:
		var chars = []
		for c in name:
			chars.append(c)		
		result.compile(".*".join(chars))
	return result


func kind_names(name) -> Array: # Array[String]
	var re = regexp_from(name)
	var matches := []
	for name in complex_kinds:
		var res = re.search(name)
		if res:
			matches.append([name, res]) 
	matches.sort_custom(ComplexRoots, "sort_result")
	var result := []
	for entry in matches:
		result.append(entry[0])
	return result

	
func properties(kind: String, name) -> Array: # Array[String]
	var re = regexp_from(name)
	var matches := []
	var kd: ComplexRoots = complex_kinds.get(kind)
	if not kd:
		return []
	for prop in kd.properties:
		var res = re.search(prop.name)
		if res:
			matches.append([prop.name, res]) 
	matches.sort_custom(ComplexRoots, "sort_result")
	var result := []
	for entry in matches:
		result.append(entry[0])
	return result

func _on_get_model_done(error: int, result: ResotoAPI.Response):
	if error == 0:
		all_kinds = load_model(result.transformed.result)	
		complex_kinds = complex_roots(all_kinds)
	else:
		print("Can not load model from core! ")
		# TODO: handle this problem

func _on_LineEdit_text_entered(text):
	print(kind_names(text)) # Replace with function body.
