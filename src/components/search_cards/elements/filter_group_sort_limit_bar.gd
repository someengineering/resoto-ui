extends PanelContainer

signal update_sort_limit

onready var sort_dir_button = $HBox/Sort/DirButton

var sort_dir:String = "asc"
var properties:Array

func _ready():
	_on_CheckButton_pressed()
	_on_ComboBox_option_changed("")


func _on_DirButton_pressed():
	sort_dir = "asc" if sort_dir_button.pressed else "desc"
	sort_dir_button.text = sort_dir
	update_string()


func _on_ComboBox_option_changed(option):
	var checked = option != ""
	$HBox/Sort/Label.modulate.a = 1.0 if checked else 0.3
	$HBox/Sort/ComboBox.modulate.a = 1.0 if checked else 0.3
	$HBox/Sort/DirButton.visible = checked
	update_string()


func update_string():
	var sort_string:= ""
	if $HBox/Sort/ComboBox.text != "":
		sort_string = " sort " + $HBox/Sort/ComboBox.text + " " + sort_dir
	
	var limit_string:= ""
	if $HBox/Limit/CheckButton.pressed:
		limit_string += " limit " + $HBox/Limit/LineEdit.text
	
	var sort_limit_string:= ""
	if sort_string != "" and limit_string != "":
		sort_limit_string += sort_string + "" + limit_string
	else:
		sort_limit_string += sort_string + limit_string
		
	emit_signal("update_sort_limit", sort_limit_string)


func _on_CheckButton_pressed():
	var checked = $HBox/Limit/CheckButton.pressed
	$HBox/Limit/Label.modulate.a = 1.0 if checked else 0.3
	$HBox/Limit/LineEdit.modulate.a = 1.0 if checked else 0.3
	update_string()


func _on_LineEdit_text_changed(new_text):
	update_string()


func _on_FilterGroup_update_elements(active_filters):
	properties = []
	for af in active_filters:
		var af_props = af.properties
		properties.append_array(af_props)
	$HBox/Sort.visible = !properties.empty()
	$HBox/Sort/ComboBox.items = properties
