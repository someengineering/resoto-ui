extends PanelContainer

var column:int = -1
var data_cell:= false
var even_row:= false
var cell_text:= "" setget set_cell_text
var cell_color:= Color.white setget set_cell_color
var min_size := 0.0

onready var label = $Label
onready var cell_bg = $CellBG

func _ready() -> void:
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func set_cell(_cell_text:String, _cell_color:Color, _column:int=-1) -> void:
	self.cell_color = _cell_color
	self.cell_text = _cell_text
	column = _column

func get_min_size() -> float:
	var font = label.get_font("font")
	var total_size = font.get_string_size(cell_text).x + 10
	return total_size

func on_mouse_entered() -> void:
	cell_bg.color = cell_color.lightened(0.06)

func on_mouse_exited() -> void:
	cell_bg.color = cell_color

func set_cell_text(_new:String) -> void:
	cell_text = _new.replace('"', "")
	label.text = cell_text
	min_size = label.rect_min_size.x
	rect_min_size.x = max(min_size, rect_min_size.x)


func set_cell_color(_new:Color) -> void:
	cell_color = _new if even_row else _new.darkened(0.15)
	cell_bg.color = cell_color
	if cell_color.get_luminance() > 0.6:
		label.add_color_override("font_color", Style.col_map[Style.c.BG])
	else:
		label.add_color_override("font_color", Style.col_map[Style.c.LIGHT].lightened(0.2))
