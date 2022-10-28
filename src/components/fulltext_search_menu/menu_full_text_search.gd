extends LineEdit

const NO_RESULT_MESSAGE = "0 results"
const ResultTemplate = preload("res://components/fulltext_search_menu/full_text_search_result_template.tscn")

var popup_x_size:int = 500
var result_limit:int = 10
var active_request: ResotoAPI.Request
var count_request: ResotoAPI.Request
var search_command:= ""
var buffered_command:= ""

onready var popup := $PopupLayer/ResultsPopUp
onready var popup_results := $PopupLayer/ResultsPopUp/VBox
onready var result_amount_label := $PopupLayer/ResultsPopUp/VBox/Title/ResultAmountLabel
onready var list_btn := $PopupLayer/ResultsPopUp/VBox/Title/ListButton

onready var single_node_info = _g.content_manager.find_node("NodeSingleInfo")
onready var search_delay := $SearchDelay


func _on_FullTextSearch_focus_entered() -> void:
	_g.focus_in_search = true
	_g.emit_signal("close_hamburger_menu")


func _on_FullTextSearch_focus_exited() -> void:
	_g.focus_in_search = false


func _on_FullTextSearch_text_changed(_command:String) -> void:
	buffered_command = _command
	if buffered_command == "":
		popup.hide()
		search_delay.stop()
	list_btn.hide()
	result_amount_label.text = ""
	result_amount_label.autowrap = false
	result_amount_label.modulate.a = 0.0
	search_delay.start()
	grab_focus()


func _on_cli_execute_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		if _response.response_code == 400:
			return
		return
	var response_text:String = _response.transformed.result
	var results_count:int = int(response_text.split("\n")[0].split(": ")[1])
	var result_count_text:String = str(results_count) + " result"
	if results_count == 0 or results_count > 1:
		result_count_text += "s"
	if results_count > result_limit:
		result_count_text += " (showing first " + str(result_limit) + ")"
	result_amount_label.text = result_count_text
	result_amount_label.modulate.a = 1.0


func _on_graph_search_done(error:int, _response:UserAgent.Response) -> void:
	if error:
		if error == ERR_PRINTER_ON_FIRE:
			return
		if _response.response_code == 400:
			show_search_results([], _response.body.get_string_from_utf8())
		else:
			_g.emit_signal("add_toast", "Error in Seasrch", "Query: "+ active_request.body, 1, self)
		return
	if _response.transformed.has("result"):
		show_search_results(_response.transformed.result)


func show_search_results(results:Array, error:="") -> void:
	grab_focus()
	# clear old results
	for c in popup_results.get_children():
		if c.get_class() == "HBoxContainer":
			continue
		c.queue_free()
	
	if text == "" or results.empty():
		if error != "":
			result_amount_label.text = error
			result_amount_label.modulate.a = 1.0
			result_amount_label.autowrap = true
			popup.show()
			yield(VisualServer, "frame_post_draw")
			popup.rect_size.y = 50
		else:
			popup.hide()
		return
	
	list_btn.show()
	
	var current_showing_id:= ""
	if single_node_info.visible and single_node_info.current_node_id != "":
		current_showing_id = single_node_info.current_node_id
	
	for r in results:
		var new_result = ResultTemplate.instance()
		new_result.show()
		if r.id == current_showing_id:
			new_result.modulate *= 1.4
		new_result.connect("pressed", self, "on_result_button_clicked", [r.id])
		new_result.hint_tooltip = "id: " + r.id
		new_result.set_meta("id", r.id)
		var ancestors:String = ""
		if r.has("ancestors"):
			if r.ancestors.has("cloud"):
				ancestors += r.ancestors.cloud.reported.name
			if r.ancestors.has("account"):
				var r_account = r.ancestors.account.reported.name
				r_account = Utils.truncate_string(r_account, new_result.get_node("VBox/ResultDetails").get_font("font"), 150.0)
				ancestors += " > " + r_account
			if r.ancestors.has("region"):
				ancestors += " > " + r.ancestors.region.reported.name
			if r.ancestors.has("zone"):
				ancestors += " > " + r.ancestors.zone.reported.name
		
		var r_name = r.reported.name
		var r_kind = r.reported.kind
		new_result.get_node("VBox/Top/ResultKind").text = r_kind
		new_result.get_node("VBox/Top/ResultName").text = r_name
		new_result.get_node("VBox/ResultDetails").text = ancestors
		popup_results.add_child(new_result)
	
	yield(VisualServer, "frame_post_draw")
	var _popup_x_size = max(popup_x_size, rect_size.x)
	var popup_pos  = rect_global_position + Vector2(-abs(_popup_x_size-rect_size.x), self.rect_size.y)
	var popup_size = Vector2(_popup_x_size, popup.rect_size.y)
	popup.rect_global_position = popup_pos
	popup.rect_size.y = 1
	popup.show()
	grab_focus()


func on_result_button_clicked(_id:String):
	popup.hide()
	_g.emit_signal("explore_node_by_id", _id)


func _on_FullTextSearch_gui_input(event):
	if (event is InputEventMouseButton
	and event.pressed
	and event.button_index == BUTTON_LEFT
	and not popup.visible):
		_on_FullTextSearch_text_changed(text)


func _on_ListButton_pressed():
	_g.emit_signal("explore_node_list_search", search_command)
	popup.hide()


func text_to_search(_text:String):
	var _new_search_command : String = ""
	if _text.to_lower().begins_with("search "):
		_new_search_command = _text.trim_prefix("search ")
	else:
		_new_search_command = "\"" + _text + "\""
	return _new_search_command


func _on_SearchDelay_timeout():
	search_command = ""
	var limited_search_command := ""
	var count_command := ""
	if buffered_command.to_lower().begins_with("search "):
		search_command = buffered_command.trim_prefix("search ")
		limited_search_command = search_command + " limit "+ str(result_limit)
		count_command = buffered_command + " | count"
	else:
		search_command = "\"" + buffered_command + "\""
		limited_search_command = search_command + " limit " + str(result_limit)
		count_command = "search \"" + buffered_command + "\" | count"
	
	count_request = API.cli_execute(count_command, self)
	active_request = API.graph_search(limited_search_command, self, "list")


func _on_FullTextSearch_text_entered(_new_text):
	popup.hide()
	search_delay.stop()
	if count_request:
		count_request.cancel(ERR_PRINTER_ON_FIRE)
	if active_request:
		active_request.cancel(ERR_PRINTER_ON_FIRE)
	_g.emit_signal("explore_node_list_search", text_to_search(text))
