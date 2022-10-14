extends PanelContainer

signal sort_requested(column, ascending)

enum Sorting {NONE, ASC, DESC}

var column:int = -1
var sorting:int = Sorting.NONE
var cell_text:= "" setget set_cell_text
var cell_color:= Color.white setget set_cell_color

onready var sort_icon = $HBox/SortIcon
onready var label = $HBox/Label
onready var cell_bg = $CellBG
onready var spacer_r = $HBox/SpacerR

func _ready() -> void:
	Style.add(sort_icon, Style.c.LIGHT)
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func set_cell(_cell_text:String, _cell_color:Color, _column:int=-1) -> void:
	self.cell_color = _cell_color
	self.cell_text = _cell_text
	column = _column

func get_min_size() -> float:
	var font = label.get_font("font")
	var total_size = font.get_string_size(cell_text).x - 6
	return total_size

func on_mouse_entered() -> void:
	cell_bg.modulate = cell_color.lightened(0.06)

func on_mouse_exited() -> void:
	cell_bg.modulate = cell_color

func set_cell_text(_new:String) -> void:
	cell_text = _new.replace('"', "")
	label.text = cell_text
	label.add_color_override("font_color", sort_icon.modulate.lightened(0.3))

func set_cell_color(_new:Color) -> void:
	cell_color = _new
	cell_bg.modulate = cell_color

func next_sort() -> void:
	sorting = wrapi(sorting+1, 1, 3)
	emit_signal("sort_requested", column, sorting == 1)
	update_sort_icon()

func reset_sort() -> void:
	sorting = 0
	update_sort_icon()

func update_sort_icon() -> void:
	match sorting:
		0:
			sort_icon.hide()
			spacer_r.show()
		1:
			spacer_r.hide()
			sort_icon.show()
			sort_icon.flip_v = true
		2:
			spacer_r.hide()
			sort_icon.show()
			sort_icon.flip_v = false

func _on_Cell_gui_input(event:InputEventMouseButton) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		next_sort()
