extends TextureRect

var severity : String = "" setget set_severity

func set_severity(new_severity : String):
	severity = new_severity
	var color = Color.white
	match severity:
		"low":
			color = Color("#89d1f1")
		"medium":
			color = Color("#fffd7e")
		"high":
			color = Color("#ff8832")
		"critical":
			color = Color("#f44444")
			
	modulate = color
