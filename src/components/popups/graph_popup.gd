extends PopupDialog

onready var graph_option : OptionButton = $GridContainer/GraphsOptionButton
onready var file_name_label : Label = $GridContainer/HBoxContainer/FileNameLabel
onready var merge_button : Button = $MergeButton
onready var load_button : Button = $GridContainer/HBoxContainer/LoadButton
onready var info_label : RichTextLabel = $Information

var graph_data

func _on_GraphPopup_about_to_show() -> void:
	API.get_graph(self)
	set_busy(false)
	merge_button.disabled = true
	file_name_label.text = ""
	info_label.text = ""


func _on_get_graph_done(error: int, response) -> void:
	if error:
		return
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


func _on_MergeButton_pressed() -> void:
	API.merge_graph(graph_option.text, graph_data, self)
	info_label.text = "Merging Graph..."
	set_busy(true)


func _on_merge_graph_done(error:int, response) -> void:
	if error:
		return
	info_label.text = JSON.print(response.transformed["result"],"\t")
	set_busy(false)


func _on_CloseButton_pressed():
	hide()

func set_busy(busy:bool):
	merge_button.disabled = busy
	load_button.disabled = busy
	graph_option.disabled = busy
