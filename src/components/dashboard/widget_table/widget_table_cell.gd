extends PanelContainer

var column:int = -1
var data_cell:= false
var even_row:= false
var cell_text:= "" setget set_cell_text
var cell_color:= Color.white setget set_cell_color
var min_size := 0.0
var node_id : String = ""

onready var label = $Label

func _ready() -> void:
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func _on_TableCell_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if node_id != "":
			_g.emit_signal("explore_node_by_id", node_id)
		else:
			_g.emit_signal("text_to_clipboard", cell_text)


func set_cell(_cell_text:String, _cell_color:Color, _column:int=-1) -> void:
	self.cell_color = _cell_color
	self.cell_text = _cell_text
	column = _column

func on_mouse_entered() -> void:
	self_modulate = cell_color.lightened(0.06)

func on_mouse_exited() -> void:
	self_modulate = cell_color

func set_cell_text(_new:String) -> void:
	cell_text = _new.replace('"', "")
	label.text = cell_text
	min_size = label.rect_min_size.x
	rect_min_size.x = max(min_size, rect_min_size.x)

func set_cell_color(_new:Color) -> void:
	cell_color = _new if even_row else _new.darkened(0.15)
	self_modulate = cell_color
	if cell_color.get_luminance() > 0.6:
		label.add_color_override("font_color", Style.col_map[Style.c.BG])
	else:
		label.add_color_override("font_color", Style.col_map[Style.c.LIGHT].lightened(0.2))
