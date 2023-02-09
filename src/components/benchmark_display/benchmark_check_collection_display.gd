extends HBoxContainer

var title : String = "" setget set_title
var passed : bool = false setget set_passed
var passing_n : int = 1 setget set_passing_n
var failing_n : int = 0 setget set_failing_n
var tooltip : String = "" setget set_tooltip

func set_title(_title : String):
	title = _title
	$Label.text = title
	
func set_passed(_passed : bool):
	passed = _passed
	$Passed.visible = passed
	$Failed.visible = !passed
	
func set_passing_n(n : int):
	passing_n = n
	$PassingNumber.text = str(n)
	update_bar()
	
func set_failing_n(n : int):
	failing_n = n
	$FailingNumber.text = str(n)
	update_bar()
	
func update_bar():
	if passing_n + failing_n == 0:
		return
	var ratio : float = float(passing_n) / (passing_n + failing_n)
	$ColorRect.material.set_shader_param("passed", ratio)

func set_label_variation(variation: String):
	$Label.theme_type_variation = variation

func set_tooltip(_tooltip: String):
	tooltip = _tooltip
	$IconTooltipHelper.tooltip_text = tooltip
	$IconTooltipHelper.visible = tooltip != ""
