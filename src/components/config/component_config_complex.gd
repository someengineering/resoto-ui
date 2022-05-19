extends VBoxContainer

var start_expanded:bool = false
var expanded:bool = false
var orig_size:int = 0

onready var expand_tween = $ExpandTween


func _ready():
	expanded = start_expanded
	orig_size = $Margin.rect_size.y
	$Margin.visible = start_expanded
	$Header/Top/Expand.pressed = start_expanded


func _on_Expand_toggled(button_pressed):
	if button_pressed == expanded:
		return
	expanded = button_pressed
	$Header/Top/Expand.pressed = expanded
	if expanded:
		$Margin.show()
		expand_tween.interpolate_property($Margin, "modulate:a", 0, 1, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		expand_tween.start()
	else:
		expand_tween.interpolate_property($Margin, "modulate:a", 1, 0, 0.1, Tween.TRANS_EXPO, Tween.EASE_IN)
		expand_tween.start()


func _on_Name_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_Expand_toggled(!$Header/Top/Expand.pressed)


func _on_ExpandTween_tween_all_completed():
	if not expanded:
		$Margin.hide()
