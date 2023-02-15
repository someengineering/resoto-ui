extends VBoxContainer
class_name BenchmarkResultDisplay

var passed : bool = false setget set_passed
var title : String = "" setget set_title
var failing_n : int = 0 setget set_failing_n
var remediation_actions : Array = [] setget set_remediation_actions
var remediation_text : String = "" setget set_remediation_text
var remediation_url : String = "" setget set_remediation_url
var severity : String = "" setget set_severity
var risk : String = ""
var detect : Dictionary = {}


func set_passed(_passed : bool):
	passed = _passed
	$Main/Passed.visible = passed
	$Main/Failed.visible = not passed
	$Secondary/RemediationText.visible = not passed
	$Main/SeverityLabel.visible = not passed
	$Main/Spacer.visible = not passed


func set_title(_title : String):
	title = _title
	$Main/Label.text = title


func set_failing_n(_failing : int):
	failing_n = _failing
	if _failing > 0:
		$Main/FailingResources.text = ("%d Resources have failed" if failing_n > 1 else "%d Resource has failed") % failing_n
	else:
		$Main/FailingResources.visible = false

func set_remediation_text_and_url(text: String, url: String):
	if url == null or url == "":
		$Secondary/RemediationText.text = text
	else:
		$Secondary/RemediationText.bbcode_text = "[url=%s]%s[/url]" % [remediation_url, remediation_text]
		
		$Secondary/RemediationText.text = text
	
func set_remediation_text(text : String):
	remediation_text = text
	set_remediation_text_and_url(remediation_text, remediation_url)
	
func set_remediation_url(url : String):
	remediation_url = url
	set_remediation_text_and_url(remediation_text, remediation_url)


func set_remediation_actions(actions : Array):
	remediation_actions = actions
	$RemediationButton.visible = not actions.empty()


func _on_RemediationText_meta_clicked(meta):
	OS.shell_open(meta)

func set_severity(_severity : String):
	severity = _severity
	$Main/SeverityLabel.text = "%s severity" % severity
	$Main/SeverityLabel.text = $Main/SeverityLabel.text.capitalize()
	
	var color = Color.white
	match severity:
		"low":
			color = Color("#44f470")
		"medium":
			color = Color.orange
		"high":
			color = Color("#f44444")
		"critical":
			color = Color("#f44444")
			$Main/SeverityLabel.text = $Main/SeverityLabel.text.to_upper()
			
	$Main/SeverityLabel.set("custom_colors/font_color", color)

func set_reported_data(reported : Dictionary):
	self.passed = reported.passed
	self.failing_n = reported.number_of_resources_failing
	self.title = reported.title
	self.remediation_text = reported.remediation.text
	self.remediation_url = reported.remediation.url
	self.severity = reported.severity
	self.risk = reported.risk
	self.detect = reported.detect
