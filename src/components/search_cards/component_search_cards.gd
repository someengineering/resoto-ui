extends Control

var all_kinds := {}
var complex_kinds := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: load model and provide kinds / 
	var request = API.get_model(self)
	pass # Replace with function body.

		
class Property:
	var name: String
	var kind: String
	var synthetic: Array

	func _init(_name: String, _kind: String, _synthetic: Array):
		name = _name
		kind = _kind
		synthetic = _synthetic
		
	func is_synthetic() -> bool:
		return not synthetic.empty()
		
	func synthetic_path() -> String:
		return ".".join(synthetic)

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

class ComplexRoot:
	var fqn: String
	var properties: Array # Array[Property]
	var bases: Array # Array[String]
	var property_by_name: Dictionary = {}# Dictionary[String, Property]
	
	func _init(_fqn: String, _properties: Array, _bases: Array):
		fqn = _fqn
		properties = _properties
		bases = _bases
		for prop in properties:
			property_by_name[prop.name] = prop


	func resolve_synthetic_props() -> ComplexRoot:		
		var props = []
		for p in properties:
			if p.is_synthetic():
				var real = property_by_name.get(p.synthetic_path())
				var prop = p.kind if real==null else real.kind
				props.append(Property.new(p.name, prop, []))
			else:
				props.append(p)
		return ComplexRoot.new(fqn, props, bases)
		

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
				
	# Flatten all nested paths until we reach simple kind
	static func prop_path(model: Dictionary, prop: Property, path: String = "") -> Array: # Array[Property]
		var kind = prop.kind
		var name = prop.name
		if kind.ends_with("[]"):
			kind = kind.substr(0, kind.length() - 2)
			name += "[*]"	
		var model_kind: Kind = model.get(kind)
		if model_kind != null and not model_kind.properties.empty():
			var result = []
			if path.empty():
				path = name+"."
			else:
				path = path + name + "."
			for nested in model_kind.properties:
				var p = prop_path(model, nested, path)
				result.append_array(p)
			return result
		else:
			return [Property.new(path+name, kind, prop.synthetic)]
				
	static func complex_roots(kinds: Dictionary) -> Dictionary:
		var roots := {}
		for kind in kinds.values():
			if kind.aggregate_root:
				var props = kind.properties.duplicate()
				for base in kind.bases:
					props.append_array(kinds[base].properties)				
				var resolved = []
				for prop in props:
					resolved.append_array(prop_path(kinds, prop))
				roots[kind.fqn] = ComplexRoot.new(kind.fqn, resolved, kind.bases).resolve_synthetic_props()
		return roots
		
	static func load_model(json: Array) -> Dictionary:
		var kinds := {}
		for m in json:
			var props = []
			for p in m.get("properties", []):
				var synth = p.get("synthetic")
				var synthetic_path = []
				if synth:
					synthetic_path = synth.get("path", [])
				props.append(Property.new(p.get("name"), p.get("kind"), synthetic_path))
			var kind = Kind.new(m.get("fqn"), m.get("runtime_kind"), props, m.get("bases", []), m.get("aggregate_root", false))
			kinds[kind.fqn] = kind
		return kinds
	

			

func _regexp_from(name) -> RegEx:
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
	var re = _regexp_from(name)
	var matches := []
	for name in complex_kinds:
		var res = re.search(name)
		if res:
			matches.append([name, res]) 
	matches.sort_custom(ComplexRoot, "sort_result")
	var result := []
	for entry in matches:
		result.append(entry[0])
	return result

	
func properties(kind: String, name) -> Array: # Array[String]
	var re = _regexp_from(name)
	var matches := []
	var kd: ComplexRoot = complex_kinds.get(kind)
	if not kd:
		return []
	for prop in kd.properties:
		var res = re.search(prop.name)
		if res:
			matches.append([prop.name, res]) 
	matches.sort_custom(ComplexRoot, "sort_result")
	var result := []
	for entry in matches:
		result.append(entry[0])
	return result

func propery(kind: String, name: String) -> Property:
	var cpl: ComplexRoot = complex_kinds.get(kind)
	if cpl:
		return cpl.property_by_name.get(name)
	return null
		

func _on_get_model_done(error: int, result: ResotoAPI.Response):
	if error == 0:
		all_kinds = ComplexRoot.load_model(result.transformed.result)	
		complex_kinds = ComplexRoot.complex_roots(all_kinds)		
	else:
		print("Can not load model from core! ")
		# TODO: handle this problem

func _on_LineEdit_text_entered(text):
	print(properties("cloud", text)) # Replace with function body.
