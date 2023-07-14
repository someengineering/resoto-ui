extends Control

export (bool) var debug_print_all_groups := false
export (bool) var debug_print_all_icons := false

func _ready():
	_g.connect("connected_to_resotocore", self, "start_timer")


func start_timer():
	$StartModelRequestDelay.start()


func _on_StartModelRequestDelay_timeout():
	if not _g.resoto_model.empty():
		queue_free()
		return
	show()
	API.get_model_flat(self)


func _on_get_model_flat_done(error: int, _response:ResotoAPI.Response):
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		_g.emit_signal("add_toast", "Error in receiving Model", "", FAILED, self)
		return
	if _response.transformed.has("result"):
		for kind in _response.transformed.result:
			if kind.has("fqn"):
				_g.resoto_model[kind.fqn] = kind
		
		# prepare icons
		var all_groups := {}
		var all_icons := {}
		for fqn in _g.resoto_model.values():
			if debug_print_all_groups and fqn.has("metadata") and fqn.metadata.has("group"):
				all_groups[fqn.metadata.group] = null
			if fqn.has("metadata") and fqn.metadata.has("icon"):
				all_icons[fqn.metadata.icon] = null
		if debug_print_all_groups:
			print("All Groups:")
			print(all_groups.keys())
		if debug_print_all_icons:
			print("All Icons:")
			print(all_icons.keys())
		
		var file_check := File.new()
		for icon_key in all_icons.keys():
			var icon_path : String = Style.icon_path % icon_key
			if file_check.file_exists(icon_path+".import"):
				Style.icon_files[icon_key] = load(icon_path)
			else:
				print("Icon '%s' not found! Using fallback." % icon_path)
				Style.icon_files[icon_key] = load(Style.icon_fallback)
		_g.emit_signal("model_loaded")
		queue_free()
