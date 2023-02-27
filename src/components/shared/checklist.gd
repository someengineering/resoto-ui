tool
extends MarginContainer

signal selection_changed(selected_items)

enum ContainerType {VERTICAL_FLOW, HORIZONTAL_FLOW, VERTICAL_LIST, HORIZONTAL_LIST}

const Containers := {
	ContainerType.HORIZONTAL_FLOW: HFlowContainer,
	ContainerType.HORIZONTAL_LIST: HBoxContainer,
	ContainerType.VERTICAL_FLOW: VFlowContainer,
	ContainerType.VERTICAL_LIST: VBoxContainer
}

export (String) var title := "" setget set_title
export (ContainerType) var container_type : int = ContainerType.VERTICAL_LIST
export (PackedScene) var item_delegate : PackedScene = null

var items := [] setget set_items
var matching_items := []
var checked_options := []

var options_container : Control = null

onready var filter_line_edit := $VBoxContainer/Controls/FiltersLineEdit
onready var scroll_container := $VBoxContainer/PanelContainer/ScrollContainer

func _ready():
	set_title(title)
	options_container = Containers[container_type].new() as Control
	options_container.size_flags_horizontal = SIZE_EXPAND_FILL
	options_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	scroll_container.add_child(options_container)

func populate_options(filter : String = filter_line_edit.text):
	for option in options_container.get_children():
		option.queue_free()
	
	if filter.strip_edges() == "":
		for item in items:
			add_option(item)
		matching_items = items.duplicate()
	else:
		matching_items.clear()
		for item in items:
			
			var item_text = item.to_lower() if item is String else item.text.to_lower()
			var edit_text = filter_line_edit.text.to_lower()
			if item_text.begins_with(edit_text) and not item in matching_items:
				matching_items.append(item)
				
		for item in items:
			var item_text = item.to_lower()
			var edit_text = filter_line_edit.text.to_lower()
			if edit_text in item_text and not item in matching_items:
				matching_items.append(item)
		
		for item in matching_items:
			add_option(item)
			
func add_option(item):
	var control
	if item_delegate != null:
		control = item_delegate.instance()
		assert("pressed" in control, "Item delegate for checklist must have 'pressed' property")
		assert("text" in control, "Item delegate for checklist must have 'text' property")
		assert(control.has_signal("toggled"), "Item delegate must have 'toggled' signal")
		assert(item is Dictionary, "Item delegate can only be used with dictionary items")
		
		for key in item:
			if key in control:
				control.set(key, item[key])
		
	elif item is String:
		control = CheckBox.new()
		control.text = item
		
	if item in checked_options:
		control.pressed = true
		
	control.connect("toggled", self, "_on_option_toggled", [item])
	options_container.add_child(control)

func _on_FiltersLineEdit_text_changed(new_text):
	populate_options(new_text)

func set_items(new_items : Array):
	items = new_items
	populate_options()


func _on_AllButton_pressed():
	checked_options = matching_items.duplicate()
	emit_signal("selection_changed", checked_options)
	populate_options()
	

func _on_NoneButton_pressed():
	checked_options = []
	emit_signal("selection_changed", checked_options)
	populate_options()


func _on_option_toggled(value : bool, option):
	if value and not option in checked_options:
		checked_options.append(option)
	elif option in checked_options:
		checked_options.remove(checked_options.find(option))
		
	emit_signal("selection_changed", checked_options)


func set_title(new_title : String):
	title = new_title
	if not is_inside_tree():
		return
	$VBoxContainer/Title.text = new_title

func select_all():
	_on_AllButton_pressed()
