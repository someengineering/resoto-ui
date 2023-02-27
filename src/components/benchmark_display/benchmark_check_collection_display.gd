extends HBoxContainer
class_name BenchmarkCollectionDisplay

var title : String = "" setget set_title
var passed : bool = false setget set_passed
var passing_n : int = 1 setget set_passing_n
var failing_n : int = 0 setget set_failing_n

func set_title(_title : String):
	title = _title
	$Label.text = title
	
func set_passed(_passed : bool):
	passed = _passed
	$Passed.visible = passed
	$Failed.visible = !passed
	
func set_passing_n(n : int):
	passing_n = n
	$FailingVsPassingWidget.passing_n = n
	
func set_failing_n(n : int):
	failing_n = n
	$FailingVsPassingWidget.failing_n = n

func set_label_variation(variation: String):
	$Label.theme_type_variation = variation
