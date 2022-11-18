extends PanelContainer

const p_string : String = "%s of %s"

var p_name : String = "" setget set_p_name
var p_total : int = 1 setget set_p_total
var p_current : int = 0 setget set_p_current

var was_reset:= false

func init(_p_name:String, _p_total:int, _p_current:int):
	set_p_name(_p_name)
	set_p_total(_p_total)
	set_p_current(_p_current)
	return self

func set_p_name(_p_name:String) -> void:
	p_name = _p_name
	name = p_name
	$C/MainElement/Label.text = p_name

func set_p_total(_p_total:int) -> void:
	p_total = _p_total
	$C/MainElement/Progressing.visible = p_total <= 1
	$C/MainElement/Progress.visible = p_total > 1
	$C/MainElement/Progress.text = p_string % [p_current, p_total]

func set_p_current(_p_current:int) -> void:
	p_current = _p_current
	$C/MainElement/Progress.text = p_string % [p_current, p_total]
	$C/MainElement/Progress.visible = (p_current < p_total and p_total > 1)
	$C/MainElement/Progressing.visible = (p_current < p_total)
	$C/MainElement/Done.visible = p_current >= p_total

func get_sub_element() -> Node:
	return $C/Sub/SubElements

func add_sub_element(_new_sub_element:Node) -> void:
	if not was_reset:
		p_total = 0
		was_reset = true
	$C/Sub/SubElements.add_child(_new_sub_element)
	if _new_sub_element.has_method("set_p_total"):
		set_p_total(_new_sub_element.p_total + p_total)
		set_p_current(_new_sub_element.p_current + p_current)
	# Would this be a good place to count sub elements progress?
