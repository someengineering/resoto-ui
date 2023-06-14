extends WizardStep

onready var default_template = $VBox/MultipleFieldStepTemplateElement
onready var element_list := $"%ElementList"

# Prompt Step
var value_path:= ""
var template:= ""
var format := ""
var out_data_format := ""
var drop_label_text := "Drop your files here"
var next_step

var single_content := false

func _ready():
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	
	
func _on_id_changed(element):
	var extension = element.file_name.get_extension()
	element.file_name = format.replace("{{key}}", element.key)
	if not element.file_name.ends_with(extension):
		element.file_name += "." + extension

func _on_files_dropped(files, _screen):
	if !is_visible_in_tree():
		return
	for file_name in files:
		var file = File.new()
		if not file.open(files[0], File.READ):
			var data = file.get_as_text()
			var element = new_element()
			
			if single_content:
				for e in element_list.get_children():
					element_list.remove_child(e)
					e.queue_free()
			
			element_list.add_child(element)
			element.value = data
			
			var original_key : String = file_name.get_file().replace( "."+file_name.get_file().get_extension(), "")
			
			var existing_keys := []
			for other in  element_list.get_children():
				if other == element:
					continue
				existing_keys.append(other.key)
				
			var i := 1
			var key := original_key
			while key in existing_keys:
				key = original_key + "(%d)" % i
				i += 1
			element.key = key
			element.file_name = format.replace("{{key}}", key)
			if not element.file_name.ends_with(file_name.get_extension()):
				element.file_name += "." + file_name.get_extension()

func start(_data:Dictionary):
	if not _data["previous_allowed"]:
		emit_signal("can_previous", false)
	if intercept_next:
		do_intercept_next = true
	var text_label = $VBox/TextLabel
	config_key = _data.config_key
	value_path = _data.value_path
	config_action = _data.action
	format = _data.format
	out_data_format = _data.out_data_format
	if _data.id_field_name != "":
		default_template.get_node("%Label").text = _data.id_field_name
	else:
		default_template.get_node("%Label").hide()
		default_template.line_edit.hide()
	if _data.content_name != "":
		default_template.get_node("%Label2").text = _data.content_name
	
	if "drop_label_text" in _data and _data.drop_label_text != "":
		drop_label_text = _data.drop_label_text
		$VBox/ScrollContainer/Label.text = drop_label_text
	
	single_content = _data.single_content
	
	text_label.percent_visible = 0
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	
	text_label.percent_visible = 0
	text_label.bbcode_text = _data["step_text"].replace("\\n", "\n")
	var duration = float(text_label.text.length()) / wizard.text_scroll_speed
	$TextAppearTween.remove_all()
	$TextAppearTween.interpolate_property(text_label, "percent_visible", 0, 1, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
	$TextAppearTween.start()
	wizard.character.state = wizard.character.States.TALK


func consume_next():
	do_intercept_next = false
	config_value_path = value_path
	var final_value : Dictionary = {}
	var out_value : Array = []
	
	for element in $"%ElementList".get_children():
		var key : String
		if default_template.line_edit.visible:
			key = format.replace("{{key}}", element.key)
		else:
			key = element.file_name
		var value : String = element.value
			
		if not element.file_content_provided_manually:
			final_value[key] = value
		
		out_value.append(out_data_format.replace("{{key}}", key).replace("{{value}}", value))
		out_value[-1] = str2var(out_value[-1])
	
	
	update_config(final_value)
	
	if out_value != []:
		var connections : Array = wizard.data.connections_from[step_id]
		var to_id = connections[0].to
		wizard.data.nodes[to_id].value = var2str(out_value)
	
	emit_signal("next")

func new_element():
	var element = null
	if template == "":
		element = default_template.duplicate()
		element.visible = true
	else:
		element = load(template).instance()
	return element


func _on_IconButtonText_pressed():
	var element = new_element()
	element_list.add_child(element)


func _on_TextAppearTween_tween_completed(_object, key):
	if key == ":percent_visible":
		wizard.character.state = wizard.character.States.IDLE


func _on_TextAppearTween_tween_all_completed():
	emit_signal("can_continue")

func forward_can_continue():
	emit_signal("can_continue")

func forward_can_previous(_can:bool):
	emit_signal("can_previous", _can)

func forward_next(_step_id:=0):
	emit_signal("next", _step_id)

func _on_ElementList_sort_children():
	$VBox/ScrollContainer/Label.visible = element_list.get_child_count() <= 0
