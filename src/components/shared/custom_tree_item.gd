class_name CustomTreeItem
extends PanelContainer

signal collapsed_changed
signal pressed(item)
signal released

export (bool) var collapsable: bool = true setget set_collapsable
export (bool) var show_connection_lines: bool = true setget set_show_connection_lines
export (Color) var connection_lines_color: Color = Color("#0f3356")

var custom_tree_item_scene := load("res://components/shared/custom_tree_item.tscn")
var main_element = null
var parent = null

onready var main_element_container := $VBoxContainer/MainContainer/MainElement
onready var sub_element_container := $VBoxContainer/SubContainer/SubElements
onready var sub_container := $VBoxContainer/SubContainer
onready var collapse_button := $VBoxContainer/MainContainer/CollapseButton
onready var spacer := $VBoxContainer/SubContainer/Spacer


func _ready():
	set_collapsable(collapsable)
	set_show_connection_lines(show_connection_lines)
	if main_element:
		set_main_element(main_element)
	else:
		set_main_element("null")

func _draw():
	if sub_container.visible and show_connection_lines:
		for element in sub_element_container.get_children():
			if not element.visible:
				continue
			var start : Vector2 = to_local(collapse_button.rect_global_position) + collapse_button.rect_size * Vector2(0.5, 1)
			var end : Vector2 = Vector2(start.x, to_local(Vector2(0, element.main_element_container.rect_global_position.y)).y + element.main_element_container.rect_size.y / 2)
			draw_line(start, end, connection_lines_color)
			start = end
			end = Vector2(start.x + spacer.rect_size.x, start.y)
			draw_line(start, end, connection_lines_color)


func set_collapsable(_collapsable: bool):
	collapsable = _collapsable and sub_container.get_child_count() > 0
	collapse_button.visible = collapsable
	update_sub_container_visibility()


func set_show_connection_lines(_show : bool):
	show_connection_lines = _show
	update_sub_container_visibility()


func set_main_element(element):
	var _main_container := $VBoxContainer/MainContainer/MainElement
	if element is Control:
		_main_container.add_child(element)
	elif element is String:
		var label := Label.new()
		label.text = element
		_main_container.add_child(label)
		element = label
	else:
		element = null
	
	main_element = element
	visible = main_element != null


func add_sub_element(element):
	var _sub_container := $VBoxContainer/SubContainer/SubElements
	
	var new_element = custom_tree_item_scene.instance()
	if element is Control:
		new_element.main_element = element
		_sub_container.add_child(new_element)
	elif element is String:
		var label := Label.new()
		label.text = element
		new_element.main_element = label
		_sub_container.add_child(new_element)
	else:
		new_element = null
	
	if new_element != null:
		new_element.connect("collapsed_changed", self, "child_collapsed_changed")
		new_element.parent = self
	update_sub_container_visibility()
	return new_element


func update_sub_container_visibility():
	if not is_inside_tree():
		yield(self, "ready")
	collapse_button.icon_tex = preload("res://assets/icons/icon_128_collapse.svg") if not collapse_button.pressed else preload("res://assets/icons/icon_128_expand.svg")
	sub_container.visible = not collapsable or (sub_element_container.get_child_count() > 0 and collapse_button.pressed)
	
	collapse_button.visible = sub_element_container.get_child_count()
	update()


func _on_CollapseButton_pressed():
	update_sub_container_visibility()

	yield(VisualServer, "frame_post_draw")
	emit_signal("collapsed_changed")
	update()


func child_collapsed_changed():
	emit_signal("collapsed_changed")
	update()


func collapse(collapse: bool):
	collapse_button.pressed = not collapse
	collapse_button.emit_signal("pressed")


func to_local(position : Vector2) -> Vector2:
	return position - rect_global_position


func _on_CustomTreeItem_visibility_changed():
	emit_signal("collapsed_changed")


func _on_MainElement_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			emit_signal("pressed", self)
		else:
			emit_signal("released")


func _on_MainElement_mouse_entered():
	var tween := get_tree().create_tween()
	tween.tween_property(main_element, "modulate", Color(1.6,1.6,1.6), 0.1)


func _on_MainElement_mouse_exited():
	var tween := get_tree().create_tween()
	tween.tween_property(main_element, "modulate", Color.white, 0.1)

