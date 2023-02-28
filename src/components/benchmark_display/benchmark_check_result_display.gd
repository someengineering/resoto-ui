extends HBoxContainer
class_name BenchmarkResultDisplay

var passed : bool = false setget set_passed
var title : String = "" setget set_title
var failing_n : int = 0 setget set_failing_n
var remediation_text : String = "" setget set_remediation_text
var remediation_url : String = "" setget set_remediation_url
var severity : String = "" setget set_severity
var risk : String = ""
var detect : Dictionary = {}
var account_id : String = ""
var id : String = ""


func _draw():
	var start : Vector2 = $Label.get_font("font").get_string_size($Label.text) + $Label.rect_position - Vector2(-5, $Label.rect_size.y / 2.0)
	var end : Vector2 =  Vector2($SeverityTexture.rect_position.x - 5, start.y)
	if start.x < end.x and not passed:
		draw_line(start, end, Color("#0f3356"))


func set_passed(_passed : bool):
	passed = _passed
	$Passed.visible = passed
	$Failed.visible = not passed
	$SeverityTexture.visible = not passed


func set_title(_title : String):
	title = _title
	$Label.text = title


func set_failing_n(_failing : int):
	failing_n = _failing
	if _failing > 0:
		$FailingResources.text = ("%d Resources failed") % failing_n
		self.passed = false
	else:
		$FailingResources.visible = false
		self.passed = true


func set_remediation_text(text : String):
	remediation_text = text
	
func set_remediation_url(url : String):
	remediation_url = url

func set_severity(_severity : String):
	severity = _severity
	$SeverityTexture.severity = severity

func set_reported_data(reported : Dictionary):
	self.passed = reported.passed
	self.failing_n = reported.number_of_resources_failing
	self.title = reported.title
	self.remediation_text = reported.remediation.text
	self.remediation_url = reported.remediation.url
	self.severity = reported.severity
	self.risk = reported.risk
	self.detect = reported.detect
	update()


func _on_BenchmarkCheckResultDisplay_visibility_changed():
	yield(VisualServer, "frame_post_draw")
	update()


func _on_BenchmarkCheckResultDisplay_resized():
	yield(VisualServer, "frame_post_draw")
	update()
