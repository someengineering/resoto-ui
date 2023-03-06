extends HBoxContainer

var severity := "critical" setget set_severity
var failing_n := 0 setget set_failing_n
var check_name := "" setget set_check_name
var categories : PoolStringArray = [] setget set_categories

const severity_colors := {
	"low" : 0x89d1f1ff,
	"medium" : 0xfffd7eff,
	"high" : 0xff8832ff,
	"critical" : 0xf44444ff
}

func set_severity(new_severity : String):
	severity = new_severity
	$Background/HBoxContainer/SeverityLabel.text = severity.capitalize()
	$Background/HBoxContainer/SeverityIcon.self_modulate = severity_colors[severity]
	
	
func set_failing_n(n : int):
	failing_n = n
	$FailingNumberLabel.text = str(n)
	
func set_check_name(new_name : String):
	check_name = new_name
	$CheckNameLabel.text = check_name
	
func set_categories(new_categories : PoolStringArray):
	categories = new_categories
	$Categories.text = categories.join(", ")
