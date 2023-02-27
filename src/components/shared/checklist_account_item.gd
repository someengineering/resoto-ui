extends CheckBox

var id : String = ""

func _ready():
	text = name if name == id else "%s(%s)" % [name, id]
