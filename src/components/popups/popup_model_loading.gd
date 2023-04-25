extends Control


func _ready():
	_g.connect("connect_to_core", self, "start_timer")


func start_timer():
	$StartModelRequestDelay.start()


func _on_StartModelRequestDelay_timeout():
	if not _g.resoto_model.empty():
		return
		
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
		queue_free()
