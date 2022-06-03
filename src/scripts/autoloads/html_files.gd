extends Node

signal file_uploaded(data)

var _on_read_ref : JavaScriptObject

func _ready() -> void:
	if OS.has_feature("HTML5"):
		_on_read_ref = JavaScript.create_callback(self, "_on_file_read_done")
		var file_reader : JavaScriptObject = (JavaScript.get_interface("reader"))
		file_reader.onloadend = _on_read_ref


func upload_file(_connect_to:Node, _slot:String = "_on_upload_file_done") -> void:
	if OS.has_feature("HTML5"):
		JavaScript.eval("uploadFile()", true)
		connect("file_uploaded", _connect_to, _slot, [], CONNECT_ONESHOT)


func _on_file_read_done(args):
	var event = args[0]
	if event.target.readyState == 2:
		print("uploaded")
		emit_signal("file_uploaded", event.target.result)
