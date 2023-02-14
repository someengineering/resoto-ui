extends HBoxContainer

var passing_n : int = 1 setget set_passing_n
var failing_n : int = 0 setget set_failing_n


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
