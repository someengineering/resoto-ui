extends Control

const severity_textures := [
	preload("res://assets/icons/icon-benchmark-severity-1.svg"),
	preload("res://assets/icons/icon-benchmark-severity-2.svg"),
	preload("res://assets/icons/icon-benchmark-severity-3.svg"),
	preload("res://assets/icons/icon-benchmark-severity-4.svg")
	]
const severity_colors := [
	"#89d1f1", "#fffd7e", "#ff8832", "#f44444"
]

var severity_hint := ""
var severity : String = "" setget set_severity
onready var icon : TextureRect = $SeverityTexture

func set_severity(new_severity : String):
	severity = new_severity
	var color_string = ""
	match severity:
		"low":
			icon.texture = severity_textures[0]
			color_string = severity_colors[0]
		"medium":
			icon.texture = severity_textures[1]
			color_string = severity_colors[1]
		"high":
			icon.texture = severity_textures[2]
			color_string = severity_colors[2]
		"critical":
			icon.texture = severity_textures[3]
			color_string = severity_colors[3]
	
	$SeverityTexture.modulate = Color(color_string)
	severity_hint = "[color=%s]" % color_string + ("%s severity" % severity ).capitalize() + "[/color]"


func _on_SeverityTexture_mouse_entered():
	_g.emit_signal("tooltip", severity_hint)


func _on_SeverityTexture_mouse_exited():
	_g.emit_signal("tooltip_hide")
