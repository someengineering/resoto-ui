extends Button

export (Texture) var icon_tex

func _ready():
	$Icon.texture = icon_tex
	_t.style($Icon, _t.col.C_LIGHT)
