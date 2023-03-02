extends TextureRect

const severity_textures := {
	"low" : preload("res://assets/icons/icon-benchmark-severity-1.svg"),
	"medium" : preload("res://assets/icons/icon-benchmark-severity-2.svg"),
	"high" : preload("res://assets/icons/icon-benchmark-severity-3.svg"),
	"critical" : preload("res://assets/icons/icon-benchmark-severity-4.svg")
	}
const severity_colors := {
	"low" : 0x89d1f1ff,
	"medium" : 0xfffd7eff,
	"high" : 0xff8832ff,
	"critical" : 0xf44444ff
}

var severity_hint := ""
var severity : String = "" setget set_severity

func set_severity(new_severity : String):
	severity = new_severity
	texture = severity_textures[severity]
	modulate = severity_colors[severity]
	severity_hint = "[color=%s]" % severity_colors[severity] + ("%s severity" % severity ).capitalize() + "[/color]"


func _on_SeverityIndicator_mouse_exited():
	_g.emit_signal("tooltip_hide")


func _on_SeverityIndicator_mouse_entered():
	_g.emit_signal("tooltip", severity_hint)
