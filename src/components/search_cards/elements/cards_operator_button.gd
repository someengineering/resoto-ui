extends Button

enum Modes {AND, OR}

var mode:int = Modes.AND

func _on_OperatorButton_pressed():
	if mode == Modes.AND:
		mode = Modes.OR
		text = "or"
	else:
		mode = Modes.AND
		text = "and"
