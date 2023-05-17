extends Node

signal file_uploaded(filename, data)

var _on_read_ref : JavaScriptObject
var _on_input_change_ref : JavaScriptObject
var file_reader : JavaScriptObject
var file_input : JavaScriptObject 

onready var local_storage : JavaScriptObject = JavaScript.get_interface("localStorage")

var last_file : String = ""

var loading : bool = false

func _ready() -> void:
	if OS.has_feature("HTML5"):
		_on_read_ref = JavaScript.create_callback(self, "_on_file_read_done")
		_on_input_change_ref = JavaScript.create_callback(self, "_on_input_change")
		file_reader = JavaScript.get_interface("reader")
		file_input = JavaScript.get_interface("input")
		file_reader.onloadend = _on_read_ref
		file_input.onchange = _on_input_change_ref


func upload_file(_connect_to:Node, _file_types:String = ".json, .txt", _slot:String = "_on_upload_file_done") -> void:
	last_file = ""
	loading = true
	if OS.has_feature("HTML5"):
		JavaScript.eval("uploadFile('%s')" % _file_types, true)
		connect("file_uploaded", _connect_to, _slot, [], CONNECT_ONESHOT)


func save_on_local_storage(item_name : String, data : String) -> void:
	local_storage.setItem(item_name, data)

func delete_from_local_storage(item_name : String):
	local_storage.removeItem(item_name)
	

func get_local_storage_keys() -> Array:
	var js_object = JavaScript.get_interface("Object")
	var keys = js_object.keys(local_storage)
	var keys_array : Array = []
	for i in keys.length:
		keys_array.append(keys[i])
	return keys_array


func load_from_local_storage(item_name : String):
	var data = local_storage.getItem(item_name)
	return data


func remove_from_local_storage(item_name : String):
	local_storage.removeItem(item_name)


func _on_file_read_done(args):
	var event = args[0]
	if event.target.readyState == 2:
		emit_signal("file_uploaded", last_file, event.target.result)
		loading = false


func _on_input_change(args):
	var event = args[0]
	if event.target.files.length:
		var file = event.target.files[0]
		last_file = file.name
		file_reader.readAsText(file)


func _notification(notification:int) -> void:
	if notification == MainLoop.NOTIFICATION_WM_FOCUS_IN and loading and last_file == "":
		emit_signal("file_uploaded", "", [])
		loading = false

