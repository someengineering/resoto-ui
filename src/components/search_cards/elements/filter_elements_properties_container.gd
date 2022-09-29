extends VBoxContainer

const Property = preload("res://components/search_cards/elements/cards_property.tscn")

var parent:Node = null

func _on_AddProperty_pressed():
	var new_prop = Property.instance()
	new_prop.parent = parent
	add_child(new_prop)
