extends PopupDialog

onready var graph_option : OptionButton = $GridContainer/GraphsOptionButton
onready var file_name_label : Label = $GridContainer/HBoxContainer/FileNameLabel
onready var merge_button : Button = $MergeButton
onready var load_button : Button = $GridContainer/HBoxContainer/LoadButton
onready var info_label : RichTextLabel = $Information

var graph_data
var graph_query_limit = 50000
var graph_query_count = 0
var graph_jsons_recieved = 0

var aux_file : File

func _on_GraphPopup_about_to_show() -> void:
	API.get_graph(self)
	set_busy(false)
	merge_button.disabled = true
	file_name_label.text = ""
	info_label.text = ""


func _on_get_graph_done(error: int, response) -> void:
	var graphs : Array = response.transformed["result"]
	graph_option.clear()
	for graph in graphs:
		graph_option.add_item(graph)


func _on_LoadButton_pressed() -> void:
	HtmlFiles.upload_file(self, ".ndjson")
	set_busy(true)
	info_label.text = "Loading File..."


func _on_upload_file_done(_filename:String, data) -> void:
	info_label.text = "Done!"
	file_name_label.text = _filename
	set_busy(false)
	graph_data = data
	if _filename != "":
		_g.emit_signal("add_toast", "File Uploaded!", "Graph file was uploaded correctly!", 0)


func _on_MergeButton_pressed() -> void:
	API.merge_graph(graph_option.text, graph_data, self)
	info_label.text = "Merging Graph..."
	set_busy(true)


func _on_merge_graph_done(error:int, response) -> void:
	if error != 0:
		_g.emit_signal("add_toast", "Failed to merge graph...", "Request failed with error " + str(error), 1)
		info_label.text = "Failed!"
	else:
		if typeof(response.transformed.result) == TYPE_STRING and response.transformed.result.begins_with("Error"):
			_g.emit_signal("add_toast", "Failed to merge graph...", "", 1)
			info_label.text = "Failed...\n" + response.transformed.result
		else:
			info_label.text = JSON.print(response.transformed["result"],"\t")
			_g.emit_signal("add_toast", "Graph Merged!", "Graph was merged correctly!", 0)
	
	set_busy(false)


func _on_CloseButton_pressed():
	hide()

func set_busy(busy:bool):
	merge_button.disabled = busy
	load_button.disabled = busy
	graph_option.disabled = busy


func _on_BackupButton_pressed():
	API.cli_execute("search --with-edges id=root -[0:]-> | count", self)
	aux_file = File.new()
	aux_file.open("./graph.ndjson", File.WRITE_READ)
	info_label.text = "Staring graph download..."


func _on_cli_execute_done(error:int, response):
	print(response.transformed.result.split("\n")[0].replace("total matched: ", ""))
	API.cli_execute_json("search --with-edges id=root -[0:]-> limit %d" % graph_query_limit, self, false)
	

func _on_cli_execute_json_data(data):
	graph_jsons_recieved += data.size()
	aux_file.store_string(data.join("\n"))
	
func _on_cli_execute_json_done(error:int, response):
	if "result" in response.transformed and response.transformed.result.size() > 0:
		graph_query_count += graph_query_limit
		info_label.text += "\nRecieved: %d" % graph_jsons_recieved
		API.cli_execute_json("search --with-edges id=root -[0:]-> limit %d, %d" % [graph_query_count, graph_query_limit], self, false)
	else:
		aux_file.close()
		aux_file.open("./graph.ndjson", File.READ)
		JavaScript.download_buffer(aux_file.get_buffer(aux_file.get_len()), "graph.ndjson")

		info_label.text += "\nFinished!"

func _on_get_full_graph_done(error:int, response):
	print(response.transformed.size())
	print(response.transformed)
