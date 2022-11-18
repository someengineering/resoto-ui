extends "res://components/elements/styled/icon_button.gd"
tool

var docs_text = "Resoto Docs (external)"
var ext_text = "External Link"

func _make_custom_tooltip(for_text):
	var tooltip = preload("res://components/shared/custom_ext_link_hint_tooltip.tscn").instance()
	tooltip.get_node("VBox/UrlLabel").text = for_text
	tooltip.get_node("VBox/HBox/DescrLabel").text = docs_text if for_text.begins_with("https://resoto.com") else ext_text
	
	return tooltip
