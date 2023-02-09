extends HBoxContainer

var passed : bool = false setget set_passed
var title : String = "" setget set_title
var failing_n : int = 0 setget set_failing_n
var remediation_actions : Array = [] setget set_remediation_actions


func set_passed(_passed : bool):
	passed = _passed
	$Passed.visible = passed
	$Failed.visible = not passed


func set_title(_title : String):
	title = _title
	$Label.text = title


func set_failing_n(_failing : int):
	failing_n = _failing
	if _failing > 0:
		$FailingResources.text = ("%d Resources have failed" if failing_n > 1 else "%d Resource has failed") % failing_n
	else:
		$FailingResources.text = "All resources have passed!"

func set_custom_tooltip(tooltip: String, url: String):
	$IconTooltipHelper.tooltip_text = tooltip
	if url:
		$IconTooltipHelper.link = url
		$IconTooltipHelper.texture = preload("res://assets/icons/icon_128_help_external_link.svg")
		
	$IconTooltipHelper.visible = tooltip != ""

func set_remediation_actions(actions : Array):
	remediation_actions = actions
	$RemediationButton.visible = not actions.empty()
