extends PanelContainer

signal tags_request_refresh

const TagElement = preload("res://components/node_info/node_info_element_tag_edit.tscn")

var node_id : String = ""

onready var tags_content := $VBox/ScrollContainer/TagsContent
onready var add_tag_popup := $AddTagPopup
onready var add_btn := $VBox/TagTitleBar/AddTagButton
onready var new_tag_var_edit := $AddTagPopup/NewTagData/NewTagVariableEdit
onready var new_tag_val_edit := $AddTagPopup/NewTagData/NewTagValueEdit


func clear():
	for c in tags_content.get_children():
		c.queue_free()
	$VBox/ScrollContainer.rect_min_size.y = 0


func create_tags(tags:Dictionary):
	if not tags.empty():
		# Sort the tags alphabetically by key
		var tag_keys : Array = tags.keys()
		var sorted_keys : Array = []
		for tk in tag_keys:
			sorted_keys.append([tk, tk.to_lower()])
		sorted_keys.sort_custom(self, "sort_tag_keys")
		
		for tag_pair in sorted_keys:
			create_tag(str(tag_pair[0]), str(tags[tag_pair[0]]))


static func sort_tag_keys(a, b) -> bool:
	return a[1] < b[1]


func create_tag(_variable:="purple", _value:="sheep"):
	var new_tag = TagElement.instance()
	tags_content.add_child(new_tag)
	new_tag.value = _value
	new_tag.variable = _variable
	new_tag.connect("search_tag", self, "search_tag")
	new_tag.connect("change_tag", self, "change_tag")
	new_tag.connect("delete_tag", self, "delete_tag")
	yield(VisualServer, "frame_post_draw")
	$VBox/ScrollContainer.rect_min_size.y = min(tags_content.rect_size.y, 290)


func _on_AddTagButton_pressed():
	new_tag_var_edit.text = ""
	new_tag_val_edit.text = ""
	add_tag_popup.popup(Rect2(rect_global_position+Vector2(0, add_btn.rect_size.y+12), Vector2(rect_size.x, 10)))


func add_tag(_variable:="purple", _value:="sheep"):
	if node_id == "":
		return
	var add_tag_query : String = "search id(\"%s\") | tag update \"%s\" \"%s\"" % [node_id, _variable, _value]
	if not _g.ui_test_mode:
		API.cli_execute(add_tag_query, self, "_on_add_tag_query_done")
	else:
		create_tag(_variable, _value)
		print(add_tag_query)


func _on_add_tag_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return
	
	var body := _r.body.get_string_from_utf8()
	
	if body.begins_with("error: "):
		_g.emit_signal("add_toast", "Couldn't add tag", body, 1, self, 3)
		return
	
	emit_signal("tags_request_refresh")
	# Refresh list
	# This has to be done when I can test it on a live installation.


func delete_tag(_tag_variable:String):
	if node_id == "":
		return
	var delete_tag_query : String = "search id(\"%s\") | tag delete \"%s\"" % [node_id, _tag_variable]
	
	if not _g.ui_test_mode:
		API.cli_execute(delete_tag_query, self, "_on_delete_tag_query_done")
	else:
		for c in tags_content.get_children():
			if c.variable == _tag_variable:
				c.queue_free()
		print(delete_tag_query)


func _on_delete_tag_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return
		
	var body := _r.body.get_string_from_utf8()
	
	if body.begins_with("error: "):
		_g.emit_signal("add_toast", "Couldn't delete tag", body, 1, self, 3)
		return
		
	emit_signal("tags_request_refresh")
	# Refresh list
	# This has to be done when I can test it on a live installation.


func change_tag(_tag_variable:String, _tag_value:String):
	if node_id == "":
		return
	var change_tag_query : String = "search id(\"%s\") | tag update \"%s\" \"%s\"" % [node_id, _tag_variable, _tag_value]
	
	if not _g.ui_test_mode:
		API.cli_execute(change_tag_query, self, "_on_change_tag_query_done")
	else:
		for c in tags_content.get_children():
			if c.variable == _tag_variable:
				c.value = _tag_value
		print(change_tag_query)


func _on_change_tag_query_done(_error:int, _r:ResotoAPI.Response):
	if _error:
		return
		
	var body := _r.body.get_string_from_utf8()

	if body.begins_with("error: "):
		_g.emit_signal("add_toast", "Couldn't update tag", body, 1, self, 3)
		return
		
	emit_signal("tags_request_refresh")
	# Refresh list
	# This has to be done when I can test it on a live installation.


func search_tag(_search_query:String):
	_g.emit_signal("explore_node_list_search", _search_query)


func _on_AddNewTagButton_pressed():
	if new_tag_var_edit.text == "":
		_g.emit_signal("add_toast", "Tag name can not be empty!", "", 2, self, 2)
		return
	add_tag_popup.hide()
	add_tag(new_tag_var_edit.text, new_tag_val_edit.text)
